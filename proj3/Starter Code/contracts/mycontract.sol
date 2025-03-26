// SPDX-License-Identifier: UNLICENSED

// DO NOT MODIFY BELOW THIS
pragma solidity ^0.8.17;

import "hardhat/console.sol";
contract Splitwise {
// DO NOT MODIFY ABOVE THIS

// ADD YOUR CONTRACT CODE BELOW

    // debts: map 2 chieu luu con no - chu no - so tien
    // G: do thi no
    // visited: da tham hay chua (duyet DFS)
    // instack: co trong stack hay khong (duyet DFS)
    // parent: cha cua node (duyet DFS)
    // allVisitedNode: danh sach cac node da tham (duyet DFS)
    // cyclePath: chu trinh
    // allUsers: danh sach tat ca users da tung tham gia giao dich
    // lastActive: thoi gian cuoi cung truy cap vao node
    mapping(address => mapping(address => uint)) private debts;
    mapping(address => address[]) private G;
    mapping(address => bool) private visited;
    mapping(address => bool) private instack;
    mapping(address => address) private parent;
    mapping(address => uint) private lastActive;
    address[] private allVisitedNode;
    address[] private cyclePath;
    address[] private allUsers;

    event IOUAdded(address indexed debtor, address indexed creditor, uint amount);

    // reset lai cac mang can dung trong DFS
    function resetAll() internal {
        for(uint i = 0; i < allVisitedNode.length; i++) {
            visited[allVisitedNode[i]] = false;
            instack[allVisitedNode[i]] = false;
            parent[allVisitedNode[i]] = address(0);
        }
        delete allVisitedNode;
        delete cyclePath;
    }

    // kiem tra user co trong contract hay khong
    function inContract(address user) public view returns (bool) {
        for(uint i = 0; i < allUsers.length; i++) {
            if(allUsers[i] == user) {
                return true;
            }
        }
        return false;
    }

    // them canh vao do thi
    function addEdge(address u, address v) internal {
        require(u != v, "You cannot owe yourself money");
        for(uint i = 0; i < G[u].length; i++) {
            if(G[u][i] == v) {
                return;
            }
        }
        if(!inContract(u)) {
            allUsers.push(u);
        }
        if(!inContract(v)) {
            allUsers.push(v);
        }
        G[u].push(v);
    }

    // DFS de tim chu trinh
    function DFS(address node) internal {
        visited[node] = true;
        instack[node] = true;
        allVisitedNode.push(node);
        for(uint i = 0; i < G[node].length; i++) {
            address next = G[node][i];
            if(!visited[next]) {
                parent[next] = node;
                DFS(next);
            } else if(instack[next]) {
                address cur = node;
                while(cur != next) {
                    cyclePath.push(cur);
                    cur = parent[cur];
                }
                cyclePath.push(next);
                return;
            }
        }
        instack[node] = false;
    }

    // tinh toan chu trinh
    function calculateCycle() internal {
        if(cyclePath.length == 0) {
            return;
        }

        uint minAmount = debts[cyclePath[1]][cyclePath[0]];
        for(uint i = 1; i + 1 < cyclePath.length; i++) {
            if(debts[cyclePath[i + 1]][cyclePath[i]] < minAmount) {
                minAmount = debts[cyclePath[i + 1]][cyclePath[i]];
            }
        }

        if(debts[cyclePath[0]][cyclePath[cyclePath.length - 1]] < minAmount) {
            minAmount = debts[cyclePath[0]][cyclePath[cyclePath.length - 1]];
        }

        for(uint i = 0; i + 1 < cyclePath.length; i++) {
            debts[cyclePath[i + 1]][cyclePath[i]] -= minAmount;
            if(debts[cyclePath[i + 1]][cyclePath[i]] == 0) {
                for(uint j = 0; j < G[cyclePath[i + 1]].length; j++) {
                    if(G[cyclePath[i + 1]][j] == cyclePath[i]) {
                        G[cyclePath[i + 1]][j] = G[cyclePath[i + 1]][G[cyclePath[i + 1]].length - 1];
                        G[cyclePath[i + 1]].pop();
                        break;
                    }
                }
            }
        }

        debts[cyclePath[0]][cyclePath[cyclePath.length - 1]] -= minAmount;
        if(debts[cyclePath[0]][cyclePath[cyclePath.length - 1]] == 0) {
            for(uint j = 0; j < G[cyclePath[0]].length; j++) {
                if(G[cyclePath[0]][j] == cyclePath[cyclePath.length - 1]) {
                    G[cyclePath[0]][j] = G[cyclePath[0]][G[cyclePath[0]].length - 1];
                    G[cyclePath[0]].pop();
                    break;
                }
            }
        }
    }

    // tra ve so tien ma debtor phai tra cho creditor
    function lookup(address debtor, address creditor) public view returns (uint) {
        return debts[debtor][creditor];
    }

    // lay danh sach toan bo users da tung tham gia giao dich
    function getUsers() public view returns (address[] memory) {
        /*console.log(allUsers.length);
        for(uint i = 0; i < allUsers.length; i++) {
            console.log(allUsers[i]);
            console.log("\n");
        }*/
        return allUsers;
    }

    // lay tong tien no cua mot nguoi nao do
    function getTotalOwed(address user) public view returns (uint) {
        uint total = 0;
        for(uint i = 0; i < allUsers.length; i++) {
            total += debts[user][allUsers[i]];
        }
        return total;
    }

    // lay lan cuoi truy cap cua mot Node
    function getLastActive(address user) public view returns (uint) {
        return lastActive[user];
    }
    
    // them so no amount tu debtor cho creditor
    function addIOU(address debtor, address creditor, uint amount) public {
        require(creditor != debtor, "You cannot owe yourself money");
        require(amount > 0, "Amount must be greater than 0");
        
        // A->B, B->A
        if(debts[creditor][debtor] > 0) {
            if(debts[creditor][debtor] > amount) {
                debts[creditor][debtor] -= amount;
                emit IOUAdded(debtor, creditor, amount);
                lastActive[debtor] = block.timestamp;
                lastActive[creditor] = block.timestamp;
                return;
            } else {
                debts[debtor][creditor] = amount - debts[creditor][debtor];
                debts[creditor][debtor] = 0;
            }
        } else {
            debts[debtor][creditor] += amount;
        }

        //A->B, B->C, C->A
        resetAll();
        addEdge(debtor, creditor);
        DFS(debtor);
        calculateCycle();
        emit IOUAdded(debtor, creditor, amount);
        lastActive[debtor] = block.timestamp;
        lastActive[creditor] = block.timestamp;
    }
}
