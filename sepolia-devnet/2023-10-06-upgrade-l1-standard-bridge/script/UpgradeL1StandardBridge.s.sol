// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "src/L1/L1StandardBridge.sol";
import "src/L1/L1CrossDomainMessenger.sol";
import "src/universal/CrossDomainMessenger.sol";
import "forge-std/Script.sol";
import "src/universal/ProxyAdmin.sol";

contract UpgradeL1StandardBridge is Script {
    address constant internal L1_STANDARD_BRIDGE_PROXY = 0x5638e55db5Fcf7A58df525F1098E8569C8DbA80c;
    address constant internal NEW_IMPLEMENTATION = 0x09753d716687D68c45a6800128eE111A412E1B1C;
    address constant internal PROXY_ADMIN = 0xC5aE9023bFA79124ffA50169E1423E733D0166f1;
    address constant internal PROXY_ADMIN_OWNER = 0xAf6E0E871f38c7B653700F7CbAEDafaa2784D430;

    function run() public {
        L1StandardBridge proxy = L1StandardBridge(payable(L1_STANDARD_BRIDGE_PROXY));

        CrossDomainMessenger messenger = proxy.messenger();
        console.log("Current L1CrossDomainMessenger value: %s", address(messenger));

        string memory version = proxy.version();
        console.log("Current L1StandardBridge version: %s", version);

        L1StandardBridge bridge = L1StandardBridge(payable(NEW_IMPLEMENTATION));
        console.log("Upgrading L1StandardBridge implementation to: %s", address(bridge));

        require(address(bridge.MESSENGER()) == address(0));
        require(address(bridge.messenger()) == address(0));
        require(address(bridge.OTHER_BRIDGE()) == Predeploys.L2_STANDARD_BRIDGE);
        require(address(bridge.otherBridge()) == Predeploys.L2_STANDARD_BRIDGE);

        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN);
        require(uint256(proxyAdmin.proxyType(L1_STANDARD_BRIDGE_PROXY)) == uint256(ProxyAdmin.ProxyType.CHUGSPLASH));

        vm.broadcast(PROXY_ADMIN_OWNER);
        proxyAdmin.upgradeAndCall({
            _proxy: payable(L1_STANDARD_BRIDGE_PROXY),
            _implementation: address(bridge),
            _data: abi.encodeCall(L1StandardBridge.initialize, (L1CrossDomainMessenger(address(messenger))))
        });

        version = proxy.version();
        console.log("New L1StandardBridge version: %s", version);
        console.log("New L1CrossDomainMessenger value: %s", address(proxy.messenger()));

        require(address(proxy.MESSENGER()) == address(messenger));
        require(address(proxy.messenger()) == address(messenger));
        require(address(proxy.OTHER_BRIDGE()) == Predeploys.L2_STANDARD_BRIDGE);
        require(address(proxy.otherBridge()) == Predeploys.L2_STANDARD_BRIDGE);
    }
}
