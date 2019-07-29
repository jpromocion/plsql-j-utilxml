/**
 * Utplsql unit test for utilxml
 * Autor: jpromocion (https://github.com/jpromocion/plsql-j-utilxml)
 * License: GNU General Public License v3.0
 */
CREATE OR REPLACE PACKAGE UT_UTILXML AS

  --%suite(Test utilxml)
  --%suitepath(test.plsql.j.utilxml)

  --%beforeall
  PROCEDURE setNlsDate;

  --%test(escapedStringXML - 01 -> Check escaped character)
  PROCEDURE escapedStringXML_01;

  --%test(escapedStringXML - 02 -> Check escaped character with CLOB)
  PROCEDURE escapedStringXML_02;

  --%test(unEscapedStringXML - 01 -> Check unescaped character)
  PROCEDURE unEscapedStringXML_01;

  --%test(unEscapedStringXML - 02 -> Check unescaped character with CLOB)
  PROCEDURE unEscapedStringXML_02;

  --%test(newDOMDocument - 01 -> Create xml)
  PROCEDURE newDOMDocument_01;

  --%test(stringToDOMDocument - 01 -> Xml parse)
  PROCEDURE stringToDOMDocument_01;

  --%test(stringToDOMDocument - 02 -> Exception with Xml empty)
  --%throws(-31032)
  PROCEDURE stringToDOMDocument_02;

  --%test(createNode - 01 -> New node root)
  PROCEDURE createNode_01;

  --%test(createNode - 02 -> New node child)
  PROCEDURE createNode_02;

  --%test(createTextNode - 01 -> New node with text)
  PROCEDURE createTextNode_01;

  --%test(createTextNode - 02 -> New node without text)
  PROCEDURE createTextNode_02;

  --%test(createAttribute - 01 -> New attribute in node)
  PROCEDURE createAttribute_01;

  --%test(createAttribute - 02 -> New empty attribute in node)
  PROCEDURE createAttribute_02;

  --%test(createAttribute - 03 -> New attribute in text node)
  PROCEDURE createAttribute_03;

  --%test(addNodeXmltype - 01 -> Add sub-xml)
  PROCEDURE addNodeXmltype_01;

  --%test(getRoot - 01 -> Recover root node)
  PROCEDURE getRoot_01;

  --%test(getNodeList - 01 -> Recover list child node)
  PROCEDURE getNodeList_01;

  --%test(getNodeList - 02 -> Recover list child root node)
  PROCEDURE getNodeList_02;

  --%test(getNode - 01 -> Search node in a document)
  PROCEDURE getNode_01;

  --%test(getNode - 02 -> Search node in a document not exists)
  PROCEDURE getNode_02;

  --%test(getNode - 03 -> Search node in a dad node)
  PROCEDURE getNode_03;

  --%test(getNode - 04 -> Search node in a dad node not exists)
  PROCEDURE getNode_04;

  --%test(getNode - 05 -> Search node in a dad node not direct child)
  PROCEDURE getNode_05;

  --%test(getAttribute - 01 -> Get attribute node DomElement)
  PROCEDURE getAttribute_01;

  --%test(getAttribute - 02 -> Get attribute node)
  PROCEDURE getAttribute_02;

  --%test(getAttribute - 03 -> Get attribute node without value)
  PROCEDURE getAttribute_03;

  --%test(getAttribute - 04 -> Get attribute node not exists)
  PROCEDURE getAttribute_04;

  --%test(getName - 01 -> Name of node)
  PROCEDURE getName_01;

  --%test(getValue - 01 -> Value of node)
  PROCEDURE getValue_01;

  --%test(getValue - 02 -> Value of node without value)
  PROCEDURE getValue_02;

  --%test(getValueCDATA - 01 -> Value of node)
  PROCEDURE getValueCDATA_01;

  --%test(getValueCDATA - 02 -> Value of node is empty)
  PROCEDURE getValueCDATA_02;

  --%test(domDocumentToXmlType - 01 -> Convert DomDocument to xmltype)
  PROCEDURE domDocumentToXmlType_01;

  --%test(xmlTypeToClob - 01 -> Convert xmltype to clob)
  PROCEDURE xmlTypeToClob_01;

  --%test(clobToXmlType - 01 -> Convert clob to xmltype)
  PROCEDURE clobToXmlType_01;

  PROCEDURE selectToXmlType_setup;

  --%test(selectToXmlType - 01 -> Normal: Select rows)
  --%beforetest(selectToXmlType_setup)
  PROCEDURE selectToXmlType_01;

  --%test(selectToXmlType - 02 -> Normal: Select without rows)
  PROCEDURE selectToXmlType_02;

  --%test(selectToXmlType - 03 -> Normal: default name node)
  --%beforetest(selectToXmlType_setup)
  PROCEDURE selectToXmlType_03;

  --%test(selectToXmlType - 04 -> Extended: Select rows only columns)
  --%beforetest(selectToXmlType_setup)
  PROCEDURE selectToXmlType_04;

  --%test(selectToXmlType - 05 -> Extended: Select rows full)
  --%beforetest(selectToXmlType_setup)
  PROCEDURE selectToXmlType_05;

  --%test(selectToXmlType - 06 -> Extended: Select without rows)
  PROCEDURE selectToXmlType_06;

  --%test(formatXmlType - 01 -> format not change xml)
  PROCEDURE formatXmlType_01;

  --%test(createNode (xmltype) - 03 -> Node create without namespace)
  PROCEDURE createNode_03;

  --%test(createNode (xmltype) - 04 -> Node create with namespace)
  PROCEDURE createNode_04;

  --%test(createNode (xmltype) - 05 -> Node create with namespace also node)
  PROCEDURE createNode_05;

  --%test(createNode (xmltype) - 06 -> father node unreachable)
  PROCEDURE createNode_06;

  --%test(createTextNode (xmltype) - 03 -> Node create without namespace)
  PROCEDURE createTextNode_03;

  --%test(createTextNode (xmltype) - 04 -> Node create with namespace)
  PROCEDURE createTextNode_04;

  --%test(createTextNode (xmltype) - 05 -> Node create with namespace also node)
  PROCEDURE createTextNode_05;

  --%test(createTextNode (xmltype) - 06 -> father node unreachable)
  PROCEDURE createTextNode_06;

  --%test(createAttribute (xmltype) - 04 -> New attribute in node)
  PROCEDURE createAttribute_04;

  --%test(createAttribute (xmltype) - 05 -> New empty attribute in node)
  PROCEDURE createAttribute_05;

  --%test(createAttribute (xmltype) - 06 -> New attribute in text node)
  PROCEDURE createAttribute_06;

  --%test(addNodeXmltype (xmltype) - 0 -> Add sub-xml)
  PROCEDURE addNodeXmltype_02;

  --%test(getNode (xmltype) - 06 -> Search node in a document)
  PROCEDURE getNode_06;

  --%test(getNode (xmltype) - 07 -> Search node in a document not exists)
  PROCEDURE getNode_07;

  --%test(getNodeList (xmltype) - 03 -> Recover list child node)
  PROCEDURE getNodeList_03;

  --%test(getAttribute (xmltype) - 05 -> Get attribute node)
  PROCEDURE getAttribute_05;

  --%test(getAttribute (xmltype) - 06 -> Get attribute node without value)
  PROCEDURE getAttribute_06;

  --%test(getAttribute (xmltype) - 07 -> Get attribute node not exists)
  PROCEDURE getAttribute_07;

  --%test(getValue (xmltype) - 03 -> Value of node)
  PROCEDURE getValue_03;

  --%test(getValue (xmltype) - 04 -> Value of node without value)
  PROCEDURE getValue_04;

  --%test(getValueLarge (xmltype) - 01 -> Value of node clob)
  PROCEDURE getValueLarge_01;

END UT_UTILXML;
/
SHOW ERRORS
