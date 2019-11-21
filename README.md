# Package Utilxml

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
