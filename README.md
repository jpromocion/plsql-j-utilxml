# Package Utilxml
![License: GPL 3.0](https://img.shields.io/badge/License-%20GPL%203.0-green.svg)
![Oracle PLSQL](https://img.shields.io/badge/Oracle%20PLSQL-11r2%2B-orange)
[![Donate PayPal](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://www.paypal.com/donate/?hosted_button_id=S2CX67ZD5C97C)

Package plsql language for XML control functions.

## Installation

Compile in your scheme.
NOTE: Required 11GR2

## Unit test
Testing with utPlsql version 3.
Execute:
```
set serveroutput on
begin
  ut.run('hr:test.plsql.j.utilxml');
end;
/
```
NOTE: replace "hr" for your scheme


## Additional documentation
Use PlDoc (http://pldoc.sourceforge.net/maven-site/) for source code documentation. (It placed in "pldoc").

Documentation execution:
```
#Windows
call pldoc.bat -doctitle 'plsql-j-utilxml' -d pldoc -inputencoding ISO-8859-15 src/*.*

#Linux:
pldoc.sh -doctitle \"plsql-j-utilxml\" -d pldoc -inputencoding ISO-8859-15 src/*.*
```
