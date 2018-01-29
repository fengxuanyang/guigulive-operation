pragma solidity ^0.4.14;
/**
 * The result of addional question is:
 * [Z, K1, K2, A, B, C, O]
 */

import './Ownable.sol';
import './SafeMath.sol';

contract Payroll is Ownable {
    using SafeMath for uint;
    
    struct Employee {
        address id;
        uint salary;
        uint lastPayday;
    }

    uint constant payDuration = 10 seconds;
    uint totalSalary = 0;
    mapping(address => Employee) public employees;
    
    modifier employeeExist(address id) {
        var employee = employees[id];
        assert(employee.id != 0x0);
        _;
    }
    
    modifier employeeNonExist(address id) {
        var employee = employees[id];
        assert(employee.id == 0x0);
        _;
    }

    function _partialPaid(Employee employee) private {
        totalSalary = totalSalary.sub(employee.salary);
        employee.id.transfer( employee.salary.mul(now.sub(employee.lastPayday)).div(payDuration) );
        employee.lastPayday = now;
    }

    function addEmployee(address employeeId, uint salary) onlyOwner employeeNonExist(employeeId) public {
        salary = salary.mul(1 ether);
        employees[employeeId] = Employee(employeeId, salary, now);
        totalSalary = totalSalary.add(employees[employeeId].salary);
    }

    function removeEmployee(address employeeId) onlyOwner employeeExist(employeeId) public {
        _partialPaid(employees[employeeId]);
        delete employees[employeeId];
    }

    function updateEmployee(address employeeId, uint salary) onlyOwner employeeExist(employeeId) public {
        _partialPaid(employees[employeeId]);
        employees[employeeId].id = employeeId;
        employees[employeeId].salary = salary.mul(1 ether);
        totalSalary = totalSalary.add(employees[employeeId].salary);
    }
    
    function changePaymentAddress(address oldId, address newId) onlyOwner employeeExist(oldId) employeeNonExist(newId) public {
        _partialPaid(employees[oldId]);
        addEmployee(newId, employees[oldId].salary);
        delete employees[oldId];
    }

    function addFund() payable public returns (uint) {
        return this.balance;
    }

    function calculateRunway() public view returns (uint) {
        return this.balance.div(totalSalary);
    }

    function hasEnoughFund() public view returns (bool) {
        return calculateRunway() > 0;
    }

    function getPaid() employeeExist(msg.sender) public {
        var id = msg.sender;
        uint nextPayday = employees[id].lastPayday.add(payDuration);
        require(nextPayday <= now);
        employees[id].id.transfer(employees[id].salary);
        employees[id].lastPayday = nextPayday;
    }
}
