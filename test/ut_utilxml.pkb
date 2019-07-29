/**
 * Utplsql unit test for utilxml
 * Autor: jpromocion (https://github.com/jpromocion/plsql-j-utilxml)
 * License: GNU General Public License v3.0
 */
SET DEFINE OFF
CREATE OR REPLACE PACKAGE BODY UT_UTILXML AS

  -- CONSTANT ---------------------------------------------------------------------
  ---------------------------------------------------------------------------------

  TEST_ESCAPED_CHARACTER CONSTANT VARCHAR2(28) := 'Abc&abc<abc>abc"abc"abc''abc''';
  SIMPLE_XML CONSTANT VARCHAR2(100) := '<?xml version="1.0"?><NODEA><NODEB>BBBB</NODEB><NODEC>cccc</NODEC></NODEA>';

  /******************************************************************
  ************* AUXILIARY *******************************************
  *******************************************************************/

  PROCEDURE setNlsDate IS
  BEGIN
    execute immediate(q'(ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY')');
  END setNlsDate;

  /**
   * Return test clob for escaped string
   * @return
   */
  FUNCTION getClobEscapedChar
  RETURN CLOB IS
    c_lob CLOB;
  BEGIN
    dbms_lob.createtemporary(c_lob, true);
    FOR i IN 1..1000 LOOP
      dbms_lob.append(c_lob, TEST_ESCAPED_CHARACTER);
    END LOOP;
    RETURN c_lob;
  END getClobEscapedChar;

  /**
   * Compare two xml
   * @param c_lob xml 1
   * @param c_lob2 xml 2
   * @return TRUE if equals
   */
  FUNCTION compareTwoXml(c_lob CLOB, c_lob2 CLOB)
  RETURN BOOLEAN IS
    xml_diff XMLTYPE;
    res BOOLEAN := TRUE;
  BEGIN

     insert into borrame values(1, c_lob);
     insert into borrame values(2, c_lob2);

    SELECT
      XMLDIFF(
        XMLTYPE(c_lob),
        XMLTYPE(c_lob2)
        )
    INTO xml_diff
    FROM DUAL;
    IF INSTR(xml_diff.getClobVal(),'append-node') > 0
      OR INSTR(xml_diff.getClobVal(),'insert-node-before') > 0
      OR INSTR(xml_diff.getClobVal(),'delete-node') > 0
      OR INSTR(xml_diff.getClobVal(),'update-node') > 0 THEN
      res := FALSE;
    END IF;

    RETURN res;
  END compareTwoXml;

  /**
   * Return test clob with xml with large node of 10000 characters
   * @return
   */
  FUNCTION getXmlLarge
  RETURN CLOB IS
    c_lob CLOB;
  BEGIN
    dbms_lob.createtemporary(c_lob, true);
    dbms_lob.append(c_lob, '<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1>');
    FOR i IN 1..2000 LOOP
      dbms_lob.append(c_lob, 'ABCDE');
    END LOOP;
    dbms_lob.append(c_lob, '</COLUMN1></b:CHILD></a:FATHER>');

    RETURN c_lob;
  END getXmlLarge;



  /******************************************************************
  ************* TEST PROCEDURE **************************************
  *******************************************************************/

  PROCEDURE escapedStringXML_01 IS
  BEGIN
    ut.expect(utilxml.escapedStringXML(TEST_ESCAPED_CHARACTER)).to_equal(
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
              TEST_ESCAPED_CHARACTER,
              '&','&amp;'),
              '<', '&lt;'),
              '>', '&gt;'),
              '"', '&quot;'),
              '''', '&apos;'));
  END escapedStringXML_01;

  PROCEDURE escapedStringXML_02 IS
    c_lob CLOB;
  BEGIN
    c_lob := getClobEscapedChar();
    ut.expect(utilxml.escapedStringXML(c_lob)).to_equal(
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
              c_lob,
              '&','&amp;'),
              '<', '&lt;'),
              '>', '&gt;'),
              '"', '&quot;'),
              '''', '&apos;'));
    dbms_lob.freetemporary(c_lob);
  END escapedStringXML_02;

  PROCEDURE unEscapedStringXML_01 IS
  BEGIN
    ut.expect(utilxml.unEscapedStringXML(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            TEST_ESCAPED_CHARACTER,
            '&','&amp;'),
            '<', '&lt;'),
            '>', '&gt;'),
            '"', '&quot;'),
            '''', '&apos;'))).to_equal(TEST_ESCAPED_CHARACTER);
  END unEscapedStringXML_01;

  PROCEDURE unEscapedStringXML_02 IS
    c_lob CLOB;
  BEGIN
    c_lob := getClobEscapedChar();
    ut.expect(utilxml.unEscapedStringXML(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            c_lob,
            '&','&amp;'),
            '<', '&lt;'),
            '>', '&gt;'),
            '"', '&quot;'),
            '''', '&apos;'))).to_equal(c_lob);
    dbms_lob.freetemporary(c_lob);
  END unEscapedStringXML_02;

  PROCEDURE newDOMDocument_01 IS
    c_lob CLOB := EMPTY_CLOB;
    c_lob2 CLOB := EMPTY_CLOB;
  BEGIN
    --data 1
    dbms_lob.createtemporary(c_lob, true);
    dbms_xmldom.writeToClob(utilxml.newDOMDocument(), c_lob);
    c_lob := REPLACE(REPLACE(c_lob, CHR(10)),' ');

    --data 2
    dbms_lob.createtemporary(c_lob2, true);
    dbms_lob.append(c_lob2, '<?xmlversion="1.0"?>');

    --to compare
    ut.expect(c_lob).to_equal(c_lob2);

    dbms_lob.freetemporary(c_lob);
    dbms_lob.freetemporary(c_lob2);
  END newDOMDocument_01;

  PROCEDURE stringToDOMDocument_01 IS
    c_lob CLOB := EMPTY_CLOB;
    c_lob2 CLOB := EMPTY_CLOB;
    diff BOOLEAN := FALSE;
  BEGIN
    --data 1
    dbms_lob.createtemporary(c_lob, true);
    dbms_xmldom.writeToClob(utilxml.stringToDOMDocument(SIMPLE_XML), c_lob);

    --data 2
    dbms_lob.createtemporary(c_lob2, true);
    dbms_lob.append(c_lob2, SIMPLE_XML);

    --to compare
    diff := NOT compareTwoXml(c_lob, c_lob2);
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
    dbms_lob.freetemporary(c_lob2);
  END stringToDOMDocument_01;

  PROCEDURE stringToDOMDocument_02 IS
    document DBMS_XMLDOM.DOMDocument;
  BEGIN
    document := utilxml.stringToDOMDocument('');
  END stringToDOMDocument_02;

  PROCEDURE createNode_01 IS
    c_lob CLOB := EMPTY_CLOB;
    c_lob2 CLOB := EMPTY_CLOB;
    diff BOOLEAN := FALSE;
    document DBMS_XMLDOM.DOMDocument;
    root_node DBMS_XMLDOM.domnode;
    node_result DBMS_XMLDOM.domnode;
  BEGIN
    --data 1
    document := utilxml.newDOMDocument();
    root_node := DBMS_XMLDOM.makenode(document);
    node_result := utilxml.createNode(document,
                        root_node,
                        'NODEA');
    dbms_lob.createtemporary(c_lob, true);
    dbms_xmldom.writeToClob(document, c_lob);

    --data2
    dbms_lob.createtemporary(c_lob2, true);
    dbms_lob.append(c_lob2, '<?xml version="1.0"?><NODEA/>');

    --to compare
    diff := NOT compareTwoXml(c_lob, c_lob2);
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
    dbms_lob.freetemporary(c_lob2);
  END createNode_01;

  PROCEDURE createNode_02 IS
    c_lob CLOB := EMPTY_CLOB;
    c_lob2 CLOB := EMPTY_CLOB;
    diff BOOLEAN := FALSE;
    document DBMS_XMLDOM.DOMDocument;
    root_node DBMS_XMLDOM.domnode;
    node_dad DBMS_XMLDOM.domnode;
    node_child DBMS_XMLDOM.domnode;
  BEGIN
    --data 1
    document := utilxml.newDOMDocument();
    root_node := DBMS_XMLDOM.makenode(document);
    node_dad := utilxml.createNode(document,
                        root_node,
                        'NODEA');
    node_child := utilxml.createNode(document,
                        node_dad,
                        'NODEB');
    dbms_lob.createtemporary(c_lob, true);
    dbms_xmldom.writeToClob(document, c_lob);

    --data2
    dbms_lob.createtemporary(c_lob2, true);
    dbms_lob.append(c_lob2, '<?xml version="1.0"?><NODEA><NODEB/></NODEA>');

    --to compare
    diff := NOT compareTwoXml(c_lob, c_lob2);
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
    dbms_lob.freetemporary(c_lob2);
  END createNode_02;

  PROCEDURE createTextNode_01 IS
    c_lob CLOB := EMPTY_CLOB;
    c_lob2 CLOB := EMPTY_CLOB;
    diff BOOLEAN := FALSE;
    document DBMS_XMLDOM.DOMDocument;
    root_node DBMS_XMLDOM.domnode;
    node_dad DBMS_XMLDOM.domnode;
    node_child DBMS_XMLDOM.domnode;
  BEGIN
    --data 1
    document := utilxml.newDOMDocument();
    root_node := DBMS_XMLDOM.makenode(document);
    node_dad := utilxml.createNode(document,
                        root_node,
                        'NODEA');
    node_child := utilxml.createTextNode(document,
                        node_dad,
                        'NODEB',
                        'texto');
    dbms_lob.createtemporary(c_lob, true);
    dbms_xmldom.writeToClob(document, c_lob);

    --data2
    dbms_lob.createtemporary(c_lob2, true);
    dbms_lob.append(c_lob2, '<?xml version="1.0"?><NODEA><NODEB>texto</NODEB></NODEA>');

    --to compare
    diff := NOT compareTwoXml(c_lob, c_lob2);
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
    dbms_lob.freetemporary(c_lob2);
  END createTextNode_01;

  PROCEDURE createTextNode_02 IS
    c_lob CLOB := EMPTY_CLOB;
    c_lob2 CLOB := EMPTY_CLOB;
    diff BOOLEAN := FALSE;
    document DBMS_XMLDOM.DOMDocument;
    root_node DBMS_XMLDOM.domnode;
    node_dad DBMS_XMLDOM.domnode;
    node_child DBMS_XMLDOM.domnode;
  BEGIN
    --data 1
    document := utilxml.newDOMDocument();
    root_node := DBMS_XMLDOM.makenode(document);
    node_dad := utilxml.createNode(document,
                        root_node,
                        'NODEA');
    node_child := utilxml.createTextNode(document,
                        node_dad,
                        'NODEB',
                        --without
                        '');
    dbms_lob.createtemporary(c_lob, true);
    dbms_xmldom.writeToClob(document, c_lob);

    --data2
    dbms_lob.createtemporary(c_lob2, true);
    dbms_lob.append(c_lob2, '<?xml version="1.0"?><NODEA><NODEB></NODEB></NODEA>');

    --to compare
    diff := NOT compareTwoXml(c_lob, c_lob2);
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
    dbms_lob.freetemporary(c_lob2);
  END createTextNode_02;

  PROCEDURE createAttribute_01 IS
    c_lob CLOB := EMPTY_CLOB;
    c_lob2 CLOB := EMPTY_CLOB;
    diff BOOLEAN := FALSE;
    document DBMS_XMLDOM.DOMDocument;
    root_node DBMS_XMLDOM.domnode;
    node_result DBMS_XMLDOM.domnode;
  BEGIN
    --data 1
    document := utilxml.newDOMDocument();
    root_node := DBMS_XMLDOM.makenode(document);
    node_result := utilxml.createNode(document,
                        root_node,
                        'NODEA');
    utilxml.createAttribute(node_result,
                        'attribute1',
                        'value1');
    dbms_lob.createtemporary(c_lob, true);
    dbms_xmldom.writeToClob(document, c_lob);

    --data2
    dbms_lob.createtemporary(c_lob2, true);
    dbms_lob.append(c_lob2, '<?xml version="1.0"?><NODEA attribute1="value1"/>');

    --to compare
    diff := NOT compareTwoXml(c_lob, c_lob2);
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
    dbms_lob.freetemporary(c_lob2);
  END createAttribute_01;

  PROCEDURE createAttribute_02 IS
    c_lob CLOB := EMPTY_CLOB;
    c_lob2 CLOB := EMPTY_CLOB;
    diff BOOLEAN := FALSE;
    document DBMS_XMLDOM.DOMDocument;
    root_node DBMS_XMLDOM.domnode;
    node_result DBMS_XMLDOM.domnode;
  BEGIN
    --data 1
    document := utilxml.newDOMDocument();
    root_node := DBMS_XMLDOM.makenode(document);
    node_result := utilxml.createNode(document,
                        root_node,
                        'NODEA');
    utilxml.createAttribute(node_result,
                        'attribute1',
                        '');
    dbms_lob.createtemporary(c_lob, true);
    dbms_xmldom.writeToClob(document, c_lob);

    --data2
    dbms_lob.createtemporary(c_lob2, true);
    dbms_lob.append(c_lob2, '<?xml version="1.0"?><NODEA attribute1=""/>');

    --to compare
    diff := NOT compareTwoXml(c_lob, c_lob2);
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
    dbms_lob.freetemporary(c_lob2);
  END createAttribute_02;

  PROCEDURE createAttribute_03 IS
    c_lob CLOB := EMPTY_CLOB;
    c_lob2 CLOB := EMPTY_CLOB;
    diff BOOLEAN := FALSE;
    document DBMS_XMLDOM.DOMDocument;
    root_node DBMS_XMLDOM.domnode;
    node_dad DBMS_XMLDOM.domnode;
    node_child DBMS_XMLDOM.domnode;
  BEGIN
    --data 1
    document := utilxml.newDOMDocument();
    root_node := DBMS_XMLDOM.makenode(document);
    node_dad := utilxml.createNode(document,
                        root_node,
                        'NODEA');
    node_child := utilxml.createTextNode(document,
                        node_dad,
                        'NODEB',
                        'texto');
    utilxml.createAttribute(node_child,
                        'attribute1',
                        'value1');
    dbms_lob.createtemporary(c_lob, true);
    dbms_xmldom.writeToClob(document, c_lob);

    --data2
    dbms_lob.createtemporary(c_lob2, true);
    dbms_lob.append(c_lob2, '<?xml version="1.0"?><NODEA><NODEB attribute1="value1">texto</NODEB></NODEA>');

    --to compare
    diff := NOT compareTwoXml(c_lob, c_lob2);
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
    dbms_lob.freetemporary(c_lob2);
  END createAttribute_03;

  PROCEDURE addNodeXmltype_01 IS
    c_lob CLOB := EMPTY_CLOB;
    c_lob2 CLOB := EMPTY_CLOB;
    diff BOOLEAN := FALSE;
    document DBMS_XMLDOM.DOMDocument;
    root_node DBMS_XMLDOM.domnode;
    node_dad DBMS_XMLDOM.domnode;
    node_subxml DBMS_XMLDOM.domnode;
    subxml XMLTYPE;
  BEGIN
    --data 1
    document := utilxml.newDOMDocument();
    root_node := DBMS_XMLDOM.makenode(document);
    node_dad := utilxml.createNode(document,
                        root_node,
                        'NODEA');
    subxml := XMLTYPE('<NODEC><NODED>hello</NODED><NODED>world</NODED></NODEC>');
    node_subxml := utilxml.addNodeXmltype(document, node_dad, subxml);
    dbms_lob.createtemporary(c_lob, true);
    dbms_xmldom.writeToClob(document, c_lob);

    --data2
    dbms_lob.createtemporary(c_lob2, true);
    dbms_lob.append(c_lob2, '<?xml version="1.0"?><NODEA><NODEC><NODED>hello</NODED><NODED>world</NODED></NODEC></NODEA>');

    --to compare
    diff := NOT compareTwoXml(c_lob, c_lob2);
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
    dbms_lob.freetemporary(c_lob2);
  END addNodeXmltype_01;

  PROCEDURE getRoot_01 IS
    document DBMS_XMLDOM.DOMDocument;
    root_node DBMS_XMLDOM.DOMElement;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/></NODEA>');
    root_node := utilxml.getRoot(document);

    ut.expect(DBMS_XMLDOM.GETTAGNAME(root_node)).to_equal('NODEA');
  END getRoot_01;

  PROCEDURE getNodeList_01 IS
    document DBMS_XMLDOM.DOMDocument;
    root_elem DBMS_XMLDOM.DOMElement;
    root_node DBMS_XMLDOM.domnode;
    list_node DBMS_XMLDOM.DOMNodeList;
    elem_node DBMS_XMLDOM.DOMNode;
    nameNodes VARCHAR2(4000);
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/><NODEC/><NODED/></NODEA>');
    root_elem := utilxml.getRoot(document);
    root_node := DBMS_XMLDOM.MAKENODE(root_elem);

    list_node := utilxml.getNodeList(root_node);
    FOR i IN 0 .. DBMS_XMLDOM.getLength(list_node) - 1 LOOP
      elem_node := DBMS_XMLDOM.item(list_node, i);
      nameNodes := nameNodes || DBMS_XMLDOM.getNodeName(elem_node);
    END LOOP;

    ut.expect(nameNodes).to_equal('NODEBNODECNODED');
  END getNodeList_01;

  PROCEDURE getNodeList_02 IS
    document DBMS_XMLDOM.DOMDocument;
    list_node DBMS_XMLDOM.DOMNodeList;
    elem_node DBMS_XMLDOM.DOMNode;
    nameNodes VARCHAR2(4000);
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/><NODEB/><NODEC/><NODED/></NODEA>');

    list_node := utilxml.getNodeList(document, 'NODEB');
    FOR i IN 0 .. DBMS_XMLDOM.getLength(list_node) - 1 LOOP
      elem_node := DBMS_XMLDOM.item(list_node, i);
      nameNodes := nameNodes || DBMS_XMLDOM.getNodeName(elem_node);
    END LOOP;

    ut.expect(nameNodes).to_equal('NODEBNODEB');
  END getNodeList_02;

  PROCEDURE getNode_01 IS
    document DBMS_XMLDOM.DOMDocument;
    node_search DBMS_XMLDOM.domnode;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/><NODEC/><NODED><NODEF/></NODED></NODEA>');
    node_search := utilxml.getNode(document, 'NODEF');

    ut.expect(DBMS_XMLDOM.getNodeName(node_search)).to_equal('NODEF');
  END getNode_01;

  PROCEDURE getNode_02 IS
    document DBMS_XMLDOM.DOMDocument;
    node_search DBMS_XMLDOM.domnode;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/><NODEC/><NODED><NODEF/></NODED></NODEA>');

    node_search := utilxml.getNode(document, 'NODEZ');

    ut.expect(DBMS_XMLDOM.getNodeName(node_search)).to_be_null();
  END getNode_02;

  PROCEDURE getNode_03 IS
    document DBMS_XMLDOM.DOMDocument;
    root_elem DBMS_XMLDOM.DOMElement;
    root_node DBMS_XMLDOM.domnode;
    node_search DBMS_XMLDOM.domnode;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/><NODEC/><NODED><NODEF/></NODED></NODEA>');
    root_elem := utilxml.getRoot(document);
    root_node := DBMS_XMLDOM.MAKENODE(root_elem);

    node_search := utilxml.getNode(root_node, 'NODEC');

    ut.expect(DBMS_XMLDOM.getNodeName(node_search)).to_equal('NODEC');
  END getNode_03;

  PROCEDURE getNode_04 IS
    document DBMS_XMLDOM.DOMDocument;
    root_elem DBMS_XMLDOM.DOMElement;
    root_node DBMS_XMLDOM.domnode;
    node_search DBMS_XMLDOM.domnode;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/><NODEC/><NODED><NODEF/></NODED></NODEA>');
    root_elem := utilxml.getRoot(document);
    root_node := DBMS_XMLDOM.MAKENODE(root_elem);

    node_search := utilxml.getNode(root_node, 'NODEZ');

    ut.expect(DBMS_XMLDOM.getNodeName(node_search)).to_be_null();
  END getNode_04;

  PROCEDURE getNode_05 IS
    document DBMS_XMLDOM.DOMDocument;
    root_elem DBMS_XMLDOM.DOMElement;
    root_node DBMS_XMLDOM.domnode;
    node_search DBMS_XMLDOM.domnode;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/><NODEC/><NODED><NODEF/></NODED></NODEA>');
    root_elem := utilxml.getRoot(document);
    root_node := DBMS_XMLDOM.MAKENODE(root_elem);

    node_search := utilxml.getNode(root_node, 'NODEF');

    ut.expect(DBMS_XMLDOM.getNodeName(node_search)).to_be_null();
  END getNode_05;

  PROCEDURE getAttribute_01 IS
    document DBMS_XMLDOM.DOMDocument;
    root_elem DBMS_XMLDOM.DOMElement;
    root_node DBMS_XMLDOM.domnode;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA attribute1="value1"><NODEB/><NODEC/><NODED><NODEF/></NODED></NODEA>');
    root_elem := utilxml.getRoot(document);

    ut.expect(utilxml.getAttribute(root_elem, 'attribute1')).to_equal('value1');
  END getAttribute_01;

  PROCEDURE getAttribute_02 IS
    document DBMS_XMLDOM.DOMDocument;
    root_elem DBMS_XMLDOM.DOMElement;
    root_node DBMS_XMLDOM.domnode;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA attribute1="value1"><NODEB/><NODEC/><NODED><NODEF/></NODED></NODEA>');
    root_elem := utilxml.getRoot(document);
    root_node := DBMS_XMLDOM.MAKENODE(root_elem);

    ut.expect(utilxml.getAttribute(root_node, 'attribute1')).to_equal('value1');
  END getAttribute_02;

  PROCEDURE getAttribute_03 IS
    document DBMS_XMLDOM.DOMDocument;
    root_elem DBMS_XMLDOM.DOMElement;
    root_node DBMS_XMLDOM.domnode;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA attribute1=""><NODEB/><NODEC/><NODED><NODEF/></NODED></NODEA>');
    root_elem := utilxml.getRoot(document);
    root_node := DBMS_XMLDOM.MAKENODE(root_elem);

    ut.expect(utilxml.getAttribute(root_node, 'attribute1')).to_be_null();
  END getAttribute_03;

  PROCEDURE getAttribute_04 IS
    document DBMS_XMLDOM.DOMDocument;
    root_elem DBMS_XMLDOM.DOMElement;
    root_node DBMS_XMLDOM.domnode;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA attribute1="value1"><NODEB/><NODEC/><NODED><NODEF/></NODED></NODEA>');
    root_elem := utilxml.getRoot(document);
    root_node := DBMS_XMLDOM.MAKENODE(root_elem);

    ut.expect(utilxml.getAttribute(root_node, 'attribute2')).to_be_null();
  END getAttribute_04;

  PROCEDURE getName_01 IS
    document DBMS_XMLDOM.DOMDocument;
    root_elem DBMS_XMLDOM.DOMElement;
    root_node DBMS_XMLDOM.domnode;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA attribute1="value1"><NODEB/><NODEC/><NODED><NODEF/></NODED></NODEA>');
    root_elem := utilxml.getRoot(document);
    root_node := DBMS_XMLDOM.MAKENODE(root_elem);

    ut.expect(utilxml.getName(root_node)).to_equal('NODEA');
  END getName_01;

  PROCEDURE getValue_01 IS
    document DBMS_XMLDOM.DOMDocument;
    node_search DBMS_XMLDOM.domnode;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/><NODEC/><NODED><NODEF>Valor1</NODEF></NODED></NODEA>');
    node_search := utilxml.getNode(document, 'NODEF');

    ut.expect(utilxml.getValue(node_search)).to_equal('Valor1');
  END getValue_01;

  PROCEDURE getValue_02 IS
    document DBMS_XMLDOM.DOMDocument;
    node_search DBMS_XMLDOM.domnode;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/><NODEC/><NODED><NODEF>Valor1</NODEF></NODED></NODEA>');
    node_search := utilxml.getNode(document, 'NODEC');

    ut.expect(utilxml.getValue(node_search)).to_be_null();
  END getValue_02;

  PROCEDURE getValueCDATA_01 IS
    document DBMS_XMLDOM.DOMDocument;
    node_search DBMS_XMLDOM.domnode;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/><NODEC/><NODED><NODEF><![CDATA[Valor1]]></NODEF></NODED></NODEA>');
    node_search := utilxml.getNode(document, 'NODEF');

    ut.expect(utilxml.getValueCDATA(node_search)).to_equal(to_clob('Valor1'));
  END getValueCDATA_01;

  PROCEDURE getValueCDATA_02 IS
    document DBMS_XMLDOM.DOMDocument;
    node_search DBMS_XMLDOM.domnode;
  BEGIN
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/><NODEC/><NODED><NODEF><![CDATA[]]></NODEF></NODED></NODEA>');
    node_search := utilxml.getNode(document, 'NODEF');

    ut.expect(utilxml.getValueCDATA(node_search)).to_be_null();
  END getValueCDATA_02;

  PROCEDURE domDocumentToXmlType_01 IS
    document DBMS_XMLDOM.DOMDocument;
    xml XMLTYPE;
    c_lob CLOB := EMPTY_CLOB;
    c_lob2 CLOB := EMPTY_CLOB;
    diff BOOLEAN := FALSE;
  BEGIN
    --data 1
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/><NODEC/><NODED><NODEF>Valor1</NODEF></NODED></NODEA>');
    dbms_lob.createtemporary(c_lob, true);
    dbms_xmldom.writeToClob(document, c_lob);

    --data 2
    xml := utilxml.domDocumentToXmlType(document);

    --to compare
    diff := NOT compareTwoXml(c_lob, xml.getclobval());
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
  END domDocumentToXmlType_01;

  PROCEDURE xmlTypeToClob_01 IS
    document DBMS_XMLDOM.DOMDocument;
    xml XMLTYPE;
    c_lob CLOB := EMPTY_CLOB;
    c_lob2 CLOB := EMPTY_CLOB;
    diff BOOLEAN := FALSE;
  BEGIN
    --data 1
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/><NODEC/><NODED><NODEF>Valor1</NODEF></NODED></NODEA>');
    dbms_lob.createtemporary(c_lob, true);
    dbms_xmldom.writeToClob(document, c_lob);
    xml := utilxml.domDocumentToXmlType(document);

    --to compare
    diff := NOT compareTwoXml(c_lob, utilxml.xmlTypeToClob(xml));
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
  END xmlTypeToClob_01;

  PROCEDURE clobToXmlType_01 IS
    document DBMS_XMLDOM.DOMDocument;
    xml XMLTYPE;
    c_lob CLOB := EMPTY_CLOB;
    c_lob2 CLOB := EMPTY_CLOB;
    diff BOOLEAN := FALSE;
  BEGIN
    --data 1
    document := utilxml.stringToDOMDocument('<?xml version="1.0"?><NODEA><NODEB/><NODEC/><NODED><NODEF>Valor1</NODEF></NODED></NODEA>');
    dbms_lob.createtemporary(c_lob, true);
    dbms_xmldom.writeToClob(document, c_lob);

    --data 2
    xml := utilxml.clobToXmlType(c_lob);

    --to compare
    diff := NOT compareTwoXml(c_lob, xml.getclobval());
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
  END clobToXmlType_01;

  PROCEDURE selectToXmlType_setup IS
  BEGIN
    DELETE HR.EMPLOYEES WHERE EMPLOYEE_ID IN (-1,-2,-3);
    INSERT INTO HR.EMPLOYEES(EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL, HIRE_DATE, JOB_ID)
    VALUES(-1, 'Steven', 'King', 'SKING2', to_date('17/06/2003','dd/mm/yyyy'), 'AD_PRES');
    INSERT INTO HR.EMPLOYEES(EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL, HIRE_DATE, JOB_ID)
    VALUES(-2, 'Neena', 'Kochhar', 'NKOCHHAR2', to_date('21/09/2005','dd/mm/yyyy'), 'AD_VP');
    INSERT INTO HR.EMPLOYEES(EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL, HIRE_DATE, JOB_ID)
    VALUES(-3, 'Lex', 'De Haan', 'LDEHAAN2', to_date('13/01/2001','dd/mm/yyyy'), 'AD_VP');
  END selectToXmlType_setup;

  PROCEDURE selectToXmlType_01 IS
    c_lob CLOB := EMPTY_CLOB;
    xml XMLTYPE;
    diff BOOLEAN := FALSE;
  BEGIN
    --data 1
    dbms_lob.createtemporary(c_lob, true);
    dbms_lob.append(c_lob,
      '<EMPLOYEES>'||
      '<EMPLOYEE><EMPLOYEE_ID>-1</EMPLOYEE_ID><FIRST_NAME>Steven</FIRST_NAME><LAST_NAME>King</LAST_NAME><EMAIL>SKING2</EMAIL><HIRE_DATE>17/06/2003</HIRE_DATE><JOB_ID>AD_PRES</JOB_ID></EMPLOYEE>' ||
      '<EMPLOYEE><EMPLOYEE_ID>-2</EMPLOYEE_ID><FIRST_NAME>Neena</FIRST_NAME><LAST_NAME>Kochhar</LAST_NAME><EMAIL>NKOCHHAR2</EMAIL><HIRE_DATE>21/09/2005</HIRE_DATE><JOB_ID>AD_VP</JOB_ID></EMPLOYEE>' ||
      '<EMPLOYEE><EMPLOYEE_ID>-3</EMPLOYEE_ID><FIRST_NAME>Lex</FIRST_NAME><LAST_NAME>De Haan</LAST_NAME><EMAIL>LDEHAAN2</EMAIL><HIRE_DATE>13/01/2001</HIRE_DATE><JOB_ID>AD_VP</JOB_ID></EMPLOYEE>' ||
      '</EMPLOYEES>'
      );


    --data 2
    xml := utilxml.selectToXmlType('SELECT * FROM HR.EMPLOYEES WHERE EMPLOYEE_ID IN (-1,-2,-3) ORDER BY EMPLOYEE_ID DESC',
                                   'EMPLOYEES',
                                   'EMPLOYEE');

    --to compare
    diff := NOT compareTwoXml(c_lob, xml.getclobval());
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
  END selectToXmlType_01;

  PROCEDURE selectToXmlType_02 IS
    xml XMLTYPE;
    sizeXml PLS_INTEGER;
  BEGIN
    xml := utilxml.selectToXmlType('SELECT * FROM HR.EMPLOYEES WHERE 1=2',
                                   'EMPLOYEES',
                                   'EMPLOYEE');
    IF xml IS NULL THEN
      sizeXml := 0;
    ELSE
      sizeXml := dbms_lob.getlength(xml.getClobVal());
    END IF;
    ut.expect( sizeXml ).to_equal(0);
  END selectToXmlType_02;

  PROCEDURE selectToXmlType_03 IS
    c_lob CLOB := EMPTY_CLOB;
    xml XMLTYPE;
    diff BOOLEAN := FALSE;
  BEGIN
    --data 1
    dbms_lob.createtemporary(c_lob, true);
    dbms_lob.append(c_lob,
      '<ROWSET>'||
      '<ROW><EMPLOYEE_ID>-1</EMPLOYEE_ID><FIRST_NAME>Steven</FIRST_NAME><LAST_NAME>King</LAST_NAME><EMAIL>SKING2</EMAIL><HIRE_DATE>17/06/2003</HIRE_DATE><JOB_ID>AD_PRES</JOB_ID></ROW>' ||
      '<ROW><EMPLOYEE_ID>-2</EMPLOYEE_ID><FIRST_NAME>Neena</FIRST_NAME><LAST_NAME>Kochhar</LAST_NAME><EMAIL>NKOCHHAR2</EMAIL><HIRE_DATE>21/09/2005</HIRE_DATE><JOB_ID>AD_VP</JOB_ID></ROW>' ||
      '<ROW><EMPLOYEE_ID>-3</EMPLOYEE_ID><FIRST_NAME>Lex</FIRST_NAME><LAST_NAME>De Haan</LAST_NAME><EMAIL>LDEHAAN2</EMAIL><HIRE_DATE>13/01/2001</HIRE_DATE><JOB_ID>AD_VP</JOB_ID></ROW>' ||
      '</ROWSET>'
      );


    --data 2
    xml := utilxml.selectToXmlType('SELECT * FROM HR.EMPLOYEES WHERE EMPLOYEE_ID IN (-1,-2,-3) ORDER BY EMPLOYEE_ID DESC');

    --to compare
    diff := NOT compareTwoXml(c_lob, xml.getclobval());
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
  END selectToXmlType_03;

  PROCEDURE selectToXmlType_04 IS
    c_lob CLOB := EMPTY_CLOB;
    xml XMLTYPE;
    diff BOOLEAN := FALSE;

    tColumns utilxml.T_COLUMNSNODES  := utilxml.T_COLUMNSNODES();
  BEGIN
    --data 1
    dbms_lob.createtemporary(c_lob, true);
    dbms_lob.append(c_lob,
      '<EMPLOYEES>'||
      '<EMPLOYEE><id>-1</id><name>Steven</name><LAST_NAME>King</LAST_NAME><EMAIL>SKING2</EMAIL><JOB_ID>AD_PRES</JOB_ID></EMPLOYEE>' ||
      '</EMPLOYEES>'
      );

    tColumns.EXTEND(5);
    tColumns(1).NAMECOLUMN := 'EMPLOYEE_ID';
    tColumns(1).NAMEXML := 'id';
    tColumns(2).NAMECOLUMN := 'FIRST_NAME';
    tColumns(2).NAMEXML := 'name';
    tColumns(3).NAMECOLUMN := 'LAST_NAME';
    tColumns(3).NAMEXML := NULL;
    tColumns(4).NAMECOLUMN := 'EMAIL';
    tColumns(4).NAMEXML := NULL;
    tColumns(5).NAMECOLUMN := 'JOB_ID';
    tColumns(5).NAMEXML := NULL;

    --data 2
    xml := utilxml.selectToXmlType('HR.EMPLOYEES',
                                   'EMPLOYEE_ID IN (-1)',
                                   'EMPLOYEES',
                                   'EMPLOYEE',
                                   tColumns);

    --to compare
    diff := NOT compareTwoXml(c_lob, xml.getclobval());
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
  END selectToXmlType_04;

  PROCEDURE selectToXmlType_05 IS
    c_lob CLOB := EMPTY_CLOB;
    xml XMLTYPE;
    diff BOOLEAN := FALSE;

    tColumns utilxml.T_COLUMNSNODES  := utilxml.T_COLUMNSNODES();
    tColumnsattributes utilxml.T_COLUMNSATTRIBUTES := utilxml.T_COLUMNSATTRIBUTES();
    tColumnsOrder utilxml.T_COLUMNSNODES  := utilxml.T_COLUMNSNODES();
  BEGIN
    --data 1
    dbms_lob.createtemporary(c_lob, true);
    dbms_lob.append(c_lob,
      '<EMPLOYEES>'||
      '<EMPLOYEE id="-1" jobid="AD_PRES"><name>Steven</name><LAST_NAME>King</LAST_NAME><EMAIL>SKING2</EMAIL></EMPLOYEE>' ||
      '<EMPLOYEE id="-2" jobid="AD_VP"><name>Neena</name><LAST_NAME>Kochhar</LAST_NAME><EMAIL>NKOCHHAR2</EMAIL></EMPLOYEE>' ||
      '<EMPLOYEE id="-3" jobid="AD_VP"><name>Lex</name><LAST_NAME>De Haan</LAST_NAME><EMAIL>LDEHAAN2</EMAIL></EMPLOYEE>' ||
      '</EMPLOYEES>'
      );

    tColumns.EXTEND(3);
    tColumns(1).NAMECOLUMN := 'FIRST_NAME';
    tColumns(1).NAMEXML := 'name';
    tColumns(2).NAMECOLUMN := 'LAST_NAME';
    tColumns(2).NAMEXML := NULL;
    tColumns(3).NAMECOLUMN := 'EMAIL';
    tColumns(3).NAMEXML := NULL;

    tColumnsattributes.EXTEND(2);
    tColumnsattributes(1).NAMECOLUMN := 'EMPLOYEE_ID';
    tColumnsattributes(1).NAMEXML := 'id';
    tColumnsattributes(2).NAMECOLUMN := 'JOB_ID';
    tColumnsattributes(2).NAMEXML := 'jobid';

    tColumnsOrder.EXTEND(1);
    tColumnsOrder(1).NAMECOLUMN := 'EMPLOYEE_ID DESC';

    --data 2
    xml := utilxml.selectToXmlType('HR.EMPLOYEES',
                                   'EMPLOYEE_ID IN (-1, -2, -3)',
                                   'EMPLOYEES',
                                   'EMPLOYEE',
                                   tColumns,
                                   tColumnsattributes,
                                   tColumnsOrder);

    --to compare
    diff := NOT compareTwoXml(c_lob, xml.getclobval());
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
  END selectToXmlType_05;

  PROCEDURE selectToXmlType_06 IS
    c_lob CLOB := EMPTY_CLOB;
    xml XMLTYPE;
    diff BOOLEAN := FALSE;

    tColumns utilxml.T_COLUMNSNODES  := utilxml.T_COLUMNSNODES();
  BEGIN

    --data 1
    dbms_lob.createtemporary(c_lob, true);
    dbms_lob.append(c_lob,
      '<EMPLOYEES></EMPLOYEES>'
      );


    tColumns.EXTEND(5);
    tColumns(1).NAMECOLUMN := 'EMPLOYEE_ID';
    tColumns(1).NAMEXML := 'id';
    tColumns(2).NAMECOLUMN := 'FIRST_NAME';
    tColumns(2).NAMEXML := 'name';
    tColumns(3).NAMECOLUMN := 'LAST_NAME';
    tColumns(3).NAMEXML := NULL;
    tColumns(4).NAMECOLUMN := 'EMAIL';
    tColumns(4).NAMEXML := NULL;
    tColumns(5).NAMECOLUMN := 'JOB_ID';
    tColumns(5).NAMEXML := NULL;

    --data 2
    xml := utilxml.selectToXmlType('HR.EMPLOYEES',
                                   '1 = 2',
                                   'EMPLOYEES',
                                   'EMPLOYEE',
                                   tColumns);

    --to compare
    diff := NOT compareTwoXml(c_lob, xml.getclobval());
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
  END selectToXmlType_06;

  PROCEDURE formatXmlType_01 IS
    c_lob CLOB := EMPTY_CLOB;
    xml XMLTYPE;
    xml2 XMLTYPE;
    diff BOOLEAN := FALSE;
  BEGIN
    dbms_lob.createtemporary(c_lob, true);
    dbms_lob.append(c_lob,
      '<EMPLOYEES>'||
      '<EMPLOYEE id="-1" jobid="AD_PRES"><name>Steven</name><LAST_NAME>King</LAST_NAME><EMAIL>SKING2</EMAIL></EMPLOYEE>' ||
      '<EMPLOYEE id="-2" jobid="AD_VP"><name>Neena</name><LAST_NAME>Kochhar</LAST_NAME><EMAIL>NKOCHHAR2</EMAIL></EMPLOYEE>' ||
      '<EMPLOYEE id="-3" jobid="AD_VP"><name>Lex</name><LAST_NAME>De Haan</LAST_NAME><EMAIL>LDEHAAN2</EMAIL></EMPLOYEE>' ||
      '</EMPLOYEES>'
      );


    xml2 := utilxml.formatXmlType(utilxml.clobToXmlType(c_lob));

    --to compare
    diff := NOT compareTwoXml(c_lob, xml2.getclobval());
    ut.expect(diff).to_be_false();

    dbms_lob.freetemporary(c_lob);
  END formatXmlType_01;

  PROCEDURE createNode_03 IS
    xml XMLTYPE;
  BEGIN
    xml := XMLTYPE('<FATHER><CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></CHILD><CHILD><COLUMN1>2</COLUMN1><COLUMN2>B</COLUMN2></CHILD></FATHER>');

    utilxml.createNode(xml,
                       '//FATHER',
                       'CHILD2');

    ut.expect(INSTR(xml.getClobVal(),'<CHILD2')).to_be_greater_than(0);
  END createNode_03;

  PROCEDURE createNode_04 IS
    xml XMLTYPE;
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD><b:CHILD><COLUMN1>2</COLUMN1><COLUMN2>B</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    utilxml.createNode(xml,
                       '//a:FATHER',
                       'CHILD2',
                       tNamespaces);

    ut.expect(INSTR(xml.getClobVal(),'<CHILD2')).to_be_greater_than(0);
  END createNode_04;

  PROCEDURE createNode_05 IS
    xml XMLTYPE;
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD><b:CHILD><COLUMN1>2</COLUMN1><COLUMN2>B</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    utilxml.createNode(xml,
                       '//a:FATHER',
                       'b:CHILD2 xmlns:b="http://b/"',
                       tNamespaces);

    ut.expect(INSTR(xml.getClobVal(),'<b:CHILD2')).to_be_greater_than(0);

  END createNode_05;

  PROCEDURE createNode_06 IS
    xml XMLTYPE;
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD><b:CHILD><COLUMN1>2</COLUMN1><COLUMN2>B</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    utilxml.createNode(xml,
                       '//a:FATHER2',
                       'CHILD2',
                       tNamespaces);

    ut.expect(INSTR(xml.getClobVal(),'<CHILD2')).to_equal(0);
  END createNode_06;

  PROCEDURE createTextNode_03 IS
    xml XMLTYPE;
  BEGIN
    xml := XMLTYPE('<FATHER><CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></CHILD><CHILD><COLUMN1>2</COLUMN1><COLUMN2>B</COLUMN2></CHILD></FATHER>');

    utilxml.createTextNode(xml,
                       '//FATHER',
                       'CHILD2',
                       'AAA');

    ut.expect(INSTR(xml.getClobVal(),'<CHILD2>AAA</CHILD2>')).to_be_greater_than(0);
  END createTextNode_03;

  PROCEDURE createTextNode_04 IS
    xml XMLTYPE;
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD><b:CHILD><COLUMN1>2</COLUMN1><COLUMN2>B</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    utilxml.createTextNode(xml,
                       '//a:FATHER',
                       'CHILD2',
                       'AAA',
                       tNamespaces);

    ut.expect(INSTR(xml.getClobVal(),'<CHILD2>AAA</CHILD2>')).to_be_greater_than(0);
  END createTextNode_04;

  PROCEDURE createTextNode_05 IS
    xml XMLTYPE;
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD><b:CHILD><COLUMN1>2</COLUMN1><COLUMN2>B</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    utilxml.createTextNode(xml,
                       '//a:FATHER',
                       'b:CHILD2 xmlns:b="http://b/"',
                       'AAA',
                       tNamespaces);

    ut.expect(INSTR(xml.getClobVal(),'<b:CHILD2 xmlns:b="http://b/">AAA</b:CHILD2>')).to_be_greater_than(0);

  END createTextNode_05;


  PROCEDURE createTextNode_06 IS
    xml XMLTYPE;
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD><b:CHILD><COLUMN1>2</COLUMN1><COLUMN2>B</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    utilxml.createTextNode(xml,
                       '//a:FATHER2',
                       'CHILD2',
                       'AAA',
                       tNamespaces);

    ut.expect(INSTR(xml.getClobVal(),'<CHILD2')).to_equal(0);
  END createTextNode_06;

  PROCEDURE createAttribute_04 IS
    xml XMLTYPE;
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD><b:CHILD><COLUMN1>2</COLUMN1><COLUMN2>B</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    utilxml.createAttribute(xml,
                       '/a:FATHER/b:CHILD',
                       'attribute1',
                       'value1',
                       tNamespaces);

    ut.expect(INSTR(xml.getClobVal(),'<b:CHILD attribute1="value1"')).to_be_greater_than(0);
  END createAttribute_04;

  PROCEDURE createAttribute_05 IS
    xml XMLTYPE;
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD><b:CHILD><COLUMN1>2</COLUMN1><COLUMN2>B</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    utilxml.createAttribute(xml,
                       '/a:FATHER/b:CHILD',
                       'attribute1',
                       '',
                       tNamespaces);

    ut.expect(INSTR(xml.getClobVal(),'<b:CHILD attribute1=""')).to_be_greater_than(0);
  END createAttribute_05;

  PROCEDURE createAttribute_06 IS
    xml XMLTYPE;
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD><b:CHILD><COLUMN1>2</COLUMN1><COLUMN2>B</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    utilxml.createAttribute(xml,
                       '/a:FATHER/b:CHILD/COLUMN1',
                       'attribute1',
                       'value1',
                       tNamespaces);

    ut.expect(INSTR(xml.getClobVal(),'<COLUMN1 attribute1="value1"')).to_be_greater_than(0);
  END createAttribute_06;

  PROCEDURE addNodeXmltype_02 IS
    xml1 XMLTYPE;
    xml2 XMLTYPE;
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml1 := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD><b:CHILD><COLUMN1>2</COLUMN1><COLUMN2>B</COLUMN2></b:CHILD></a:FATHER>');

    xml2 := XMLTYPE('<CHILD2><COLUMN1>A</COLUMN1><COLUMN2>A</COLUMN2></CHILD2>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    utilxml.addNodeXmltype(xml1,
                       '/a:FATHER',
                       'CHILD2',
                       xml2,
                       tNamespaces);

    ut.expect(INSTR(xml1.getClobVal(),'<CHILD2')).to_be_greater_than(0);
  END addNodeXmltype_02;

  PROCEDURE getNode_06 IS
    xml XMLTYPE;
    xmlNode XMLTYPE;
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    xmlNode := utilxml.getNode(
                  xml,
                  '/a:FATHER/b:CHILD/COLUMN1',
                  tNamespaces);

    ut.expect(dbms_lob.substr(xmlNode.getClobVal(),4000,1)).to_equal('<COLUMN1>1</COLUMN1>');
  END getNode_06;

  PROCEDURE getNode_07 IS
    xml XMLTYPE;
    xmlNode XMLTYPE;
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
    sizeXml PLS_INTEGER;
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    xmlNode := utilxml.getNode(
                  xml,
                  '/a:FATHER/b:CHILD/COLUMN20000',
                  tNamespaces);

    IF xmlNode IS NULL THEN
      sizeXml := 0;
    ELSE
      sizeXml := dbms_lob.getlength(xmlNode.getClobVal());
    END IF;
    ut.expect( sizeXml ).to_equal(0);
  END getNode_07;

  PROCEDURE getNodeList_03 IS
    TYPE T_CURSOR IS RECORD(
      MYNAME1 VARCHAR2(100),
      MYNAME2 VARCHAR2(100)
      );

    cur SYS_REFCURSOR;
    rcursor T_CURSOR;
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
    listColumns UTILXML.T_NODES;
  BEGIN

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    listColumns(1).NAME := 'COLUMN1';
    listColumns(2).NAME := 'COLUMN2';

    cur := UTILXML.getNodeList(XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1>1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD><b:CHILD><COLUMN1>2</COLUMN1><COLUMN2>B</COLUMN2></b:CHILD></a:FATHER>'),
                       '//a:FATHER/b:CHILD',
                       listColumns,
                       tNamespaces);

    IF cur%ISOPEN THEN
      ut.expect( cur ).to_have_count(2);
    ELSE
      ut.expect( FALSE ).to_be_true();
    END IF;
  END getNodeList_03;

  PROCEDURE getAttribute_05 IS
    xml XMLTYPE;
    valueAtt VARCHAR2(4000);
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1 attribute1="value1">1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    valueAtt := utilxml.getAttribute(
                  xml,
                  '/a:FATHER/b:CHILD/COLUMN1/@attribute1',
                  tNamespaces);

    ut.expect( valueAtt ).to_equal('value1');
  END getAttribute_05;


  PROCEDURE getAttribute_06 IS
    xml XMLTYPE;
    valueAtt VARCHAR2(4000);
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1 attribute1="">1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    valueAtt := utilxml.getAttribute(
                  xml,
                  '/a:FATHER/b:CHILD/COLUMN1/@attribute1',
                  tNamespaces);

    ut.expect( valueAtt ).to_be_null();
  END getAttribute_06;

  PROCEDURE getAttribute_07 IS
    xml XMLTYPE;
    valueAtt VARCHAR2(4000);
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1 attribute1="">1</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    valueAtt := utilxml.getAttribute(
                  xml,
                  '/a:FATHER/b:CHILD/COLUMN1/@attribute2000',
                  tNamespaces);

    ut.expect( valueAtt ).to_be_null();
  END getAttribute_07;

  PROCEDURE getValue_03 IS
    xml XMLTYPE;
    valueNode VARCHAR2(4000);
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1 attribute1="value1">1234</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    valueNode := utilxml.getValue(
                  xml,
                  '/a:FATHER/b:CHILD/COLUMN1',
                  tNamespaces);

    ut.expect( valueNode ).to_equal('1234');
  END getValue_03;

  PROCEDURE getValue_04 IS
    xml XMLTYPE;
    valueNode VARCHAR2(4000);
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    xml := XMLTYPE('<a:FATHER xmlns:a="http://a/" xmlns:b="http://b/"><b:CHILD><COLUMN1 attribute1="value1">1234</COLUMN1><COLUMN2>A</COLUMN2></b:CHILD></a:FATHER>');

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    valueNode := utilxml.getValue(
                  xml,
                  '/a:FATHER/b:CHILD',
                  tNamespaces);

    ut.expect( valueNode ).to_be_null();
  END getValue_04;

  PROCEDURE getValueLarge_01 IS
    c_lob CLOB := EMPTY_CLOB;
    xml XMLTYPE;
    c_lob2 CLOB := EMPTY_CLOB;
    tNamespaces UTILXML.T_NAMESPACES  := UTILXML.T_NAMESPACES();
  BEGIN
    c_lob := getXmlLarge();
    xml := XMLTYPE(c_lob);

    tNamespaces.EXTEND(2);
    tNamespaces(1).PREFIX := 'xmlns';
    tNamespaces(1).NAMESPACE := 'a';
    tNamespaces(1).VALUE := 'http://a/';
    tNamespaces(2).PREFIX := 'xmlns';
    tNamespaces(2).NAMESPACE := 'b';
    tNamespaces(2).VALUE := 'http://b/';

    c_lob2 := utilxml.getValueLarge(
                  xml,
                  '/a:FATHER/b:CHILD',
                  'COLUMN1',
                  tNamespaces);

    ut.expect( dbms_lob.getlength(c_lob2) ).to_equal(10000);

    dbms_lob.freetemporary(c_lob);
    dbms_lob.freetemporary(c_lob2);
  END getValueLarge_01;


END UT_UTILXML;
/
SHOW ERRORS
