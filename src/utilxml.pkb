/**
 * Util package handle xml - plsql
 * Autor: jpromocion (https://github.com/jpromocion/plsql-j-utilxml)
 * License: GNU General Public License v3.0
 */
CREATE OR REPLACE PACKAGE BODY UTILXML AS

  /*
   *******************************************************************************
   ********************* PRIVATE *********************************
   *******************************************************************************
   */

  /**
   * Return literal string of namespace
   * @param tNameSpaces Table with all necessary namespace.
   * @return Literal namespace string
   */
  FUNCTION getNameSpaceString(tNameSpaces T_NAMESPACES)
  RETURN VARCHAR2 IS
    nameSpace VARCHAR2(4000);
  BEGIN
    IF tNameSpaces IS NOT NULL AND tNameSpaces.COUNT > 0 THEN
      FOR i IN tNameSpaces.FIRST..tNameSpaces.LAST LOOP
        IF tNameSpaces.EXISTS(i) THEN
          nameSpace := nameSpace || tNameSpaces(i).PREFIX || ':' || tNameSpaces(i).NAMESPACE ||
                       '="' || tNameSpaces(i).VALUE || '" ';
        END IF;
      END LOOP;
    END IF;
    RETURN nameSpace;
  END getNameSpaceString;

  /**
   * For a XMLTABLE select, add namespace information
   * @param sqlSelect Buildinf select. It will be completed
   * @param Table with all necessary namespace. If not namespace -> NULL.
   */
  PROCEDURE addNameSpaceXmlTable(sqlSelect IN OUT VARCHAR2,
                                 tNameSpaces T_NAMESPACES) IS
  BEGIN
    --if exists, add name space data
    IF tNameSpaces IS NOT NULL AND tNameSpaces.COUNT > 0 THEN
      sqlSelect := sqlSelect || CHR(10) ||
        '        xmlnamespaces (' || CHR(10);
      FOR i IN tNameSpaces.FIRST..tNameSpaces.LAST LOOP
        IF tNameSpaces.EXISTS(i) THEN
          sqlSelect := sqlSelect ||
            q'(  ')' || tNameSpaces(i).VALUE || q'('as ")' || tNameSpaces(i).NAMESPACE || '"' || CHR(10);
          IF i <> tNameSpaces.LAST THEN
            sqlSelect := sqlSelect || ', ';
          END IF;
        END IF;
      END LOOP;
      sqlSelect := sqlSelect || '        ), '|| CHR(10);
    END IF;
  END addNameSpaceXmlTable;

  /*
   *******************************************************************************
   ********************* GENERAL USE *********************************
   *******************************************************************************
   */

  FUNCTION escapedStringXML(string VARCHAR2)
  RETURN VARCHAR2 IS
  BEGIN
    RETURN DBMS_XMLGEN.CONVERT(string, 0);
  END escapedStringXML;

  FUNCTION escapedStringXML(string CLOB)
  RETURN CLOB IS
  BEGIN
    RETURN DBMS_XMLGEN.CONVERT(string, 0);
  END escapedStringXML;

  FUNCTION unEscapedStringXML(string VARCHAR2)
  RETURN VARCHAR2 IS
  BEGIN
    RETURN DBMS_XMLGEN.CONVERT(string, 1);
  END unEscapedStringXML;

  FUNCTION unEscapedStringXML(string CLOB)
  RETURN CLOB IS
  BEGIN
    RETURN DBMS_XMLGEN.CONVERT(string, 1);
  END unEscapedStringXML;

  /*
   *******************************************************************************
   ********************* USE PACKAGE DBMS_XMLDOM *********************************
   *******************************************************************************
   */

   /**
    * Create new DOMDocument without root node
    * @return new DOMDocument xml
    */
   FUNCTION newDOMDocument
   RETURN DBMS_XMLDOM.DOMDocument IS
     document DBMS_XMLDOM.domdocument;
     root_node DBMS_XMLDOM.domnode;
   BEGIN
     document := DBMS_XMLDOM.newdomdocument;
     DBMS_XMLDOM.setversion(document, '1.0');
     root_node := DBMS_XMLDOM.makenode(document);

     RETURN document;
   END newDOMDocument;


  FUNCTION stringToDOMDocument(xml VARCHAR2)
  RETURN DBMS_XMLDOM.DOMDocument IS
    retDoc DBMS_XMLDOM.DOMDocument;
    parser xmlparser.parser;
  BEGIN
    parser := xmlparser.newParser;
    xmlParser.parseBuffer(parser, xml);
    retDoc := xmlParser.getDocument(parser);
    xmlparser.freeParser(parser);
    RETURN retDoc;
  END stringToDOMDocument;

  FUNCTION stringToDOMDocument(xml CLOB)
  RETURN DBMS_XMLDOM.DOMDocument IS
    retDoc DBMS_XMLDOM.DOMDocument;
    parser xmlparser.parser;
  BEGIN
    parser := xmlparser.newParser;
    xmlparser.parseClob(parser, xml);
    retDoc := xmlParser.getDocument(parser);
    xmlparser.freeParser(parser);
    RETURN retDoc;
  END stringToDOMDocument;

  FUNCTION createNode(document DBMS_XMLDOM.DOMDocument,
                      dadNode DBMS_XMLDOM.DOMNode,
                      nameNode VARCHAR2)
  RETURN DBMS_XMLDOM.DOMNode IS
    dom_node DBMS_XMLDOM.domnode;
    domElement DBMS_XMLDOM.domelement;
  BEGIN
    --Create node
    domElement := DBMS_XMLDOM.createelement(document, nameNode);

    --Add node to father
    dom_node :=
          DBMS_XMLDOM.appendchild(dadNode, DBMS_XMLDOM.makenode(domElement));

    RETURN dom_node;
  END createNode;

  FUNCTION createTextNode(document DBMS_XMLDOM.DOMDocument,
                          dadNode DBMS_XMLDOM.DOMNode,
                          nameNode VARCHAR2,
                          text VARCHAR2)
  RETURN DBMS_XMLDOM.DOMNode IS
    dom_node DBMS_XMLDOM.domnode;
    domElement DBMS_XMLDOM.domelement;
    dom_text DBMS_XMLDOM.domtext;
    text_node DBMS_XMLDOM.domnode;
  BEGIN
    --Create normal node
    dom_node := createNode(document, dadNode, nameNode);

    --Creare text node in document
    dom_text := DBMS_XMLDOM.createTextNode(document, text);

    --assign node and text node
    text_node := DBMS_XMLDOM.appendchild(dom_node, DBMS_XMLDOM.makenode(dom_text) );

    RETURN dom_node;
  END createTextNode;

  PROCEDURE createAttribute(node DBMS_XMLDOM.DOMNode,
                            name VARCHAR2,
                            value VARCHAR2) IS
    domElement DBMS_XMLDOM.domelement;
  BEGIN
    domElement := DBMS_XMLDOM.makeElement(node);
    DBMS_XMLDOM.setattribute(domElement, name, value);
  END createAttribute;

  FUNCTION addNodeXmltype(xml DBMS_XMLDOM.DOMDocument,
                          dadNode  DBMS_XMLDOM.DOMNode,
                          xmlNode XMLTYPE)
  RETURN DBMS_XMLDOM.DOMNode IS
    documentChild DBMS_XMLDOM.DOMDocument;
    elementChild  DBMS_XMLDOM.DOMElement;
    nodeChild DBMS_XMLDOM.DOMNode;
    nodeFinal DBMS_XMLDOM.DOMNode;
  BEGIN --crearNodoXmltype

    --Create child node like new document, y extract DOMElement
    documentChild := DBMS_XMLDOM.newDomDocument(xmlNode);
    elementChild := DBMS_XMLDOM.getDocumentElement(documentChild);

    --Import new DOMElement to our xml and create like DOMElement
    nodeChild := DBMS_XMLDOM.importNode(xml, DBMS_XMLDOM.makeNode(elementChild), TRUE);
    elementChild := DBMS_XMLDOM.makeElement(nodeChild);

    --Add child element to our father node
    nodeFinal := DBMS_XMLDOM.appendChild(dadNode, DBMS_XMLDOM.makeNode(elementChild));

    RETURN nodeFinal;
  END addNodeXmltype;

  FUNCTION getRoot(document DBMS_XMLDOM.DOMDocument)
  RETURN DBMS_XMLDOM.DOMElement IS
    domElement DBMS_XMLDOM.DOMElement;
  BEGIN
    domElement := DBMS_XMLDOM.getDocumentElement(document);

    RETURN domElement;
  END getRoot;

  FUNCTION getNodeList(document DBMS_XMLDOM.DOMDocument,
                       nameNode VARCHAR2)
  RETURN DBMS_XMLDOM.DOMNodeList IS
    domElement DBMS_XMLDOM.DOMElement;
    nodeList DBMS_XMLDOM.DOMNodeList;

  BEGIN
    domElement := getRoot(document);
    nodeList := DBMS_XMLDOM.getElementsByTagName(domElement, nameNode);

    IF NOT DBMS_XMLDOM.isNull(nodeList)
       AND DBMS_XMLDOM.getLength(nodeList) > 0 THEN
      RETURN nodeList;
    END IF;

    RETURN NULL;
  END getNodeList;

  FUNCTION getNodeList(dadNode DBMS_XMLDOM.DOMNode)
  RETURN DBMS_XMLDOM.DOMNodeList IS
    nodeList DBMS_XMLDOM.DOMNodeList;
  BEGIN
    nodeList := DBMS_XMLDOM.getChildNodes(dadNode);

    IF NOT DBMS_XMLDOM.isNull(nodeList)
       AND DBMS_XMLDOM.getLength(nodeList) > 0 THEN
      RETURN nodeList;
    END IF;

    RETURN NULL;
  END getNodeList;

  FUNCTION getNode(document DBMS_XMLDOM.DOMDocument,
                   nameNode VARCHAR2)
  RETURN DBMS_XMLDOM.DOMNode IS
    domElement DBMS_XMLDOM.DOMElement;
    nodeResult DBMS_XMLDOM.DOMNode;
    nodeList DBMS_XMLDOM.DOMNodelist;
  BEGIN
    domElement := DBMS_XMLDOM.getDocumentElement(document);
    nodelist := DBMS_XMLDOM.getElementsByTagName(domElement, nameNode);
    nodeResult := DBMS_XMLDOM.item(nodeList, 0);

    RETURN(nodeResult);
  END getNode;

  FUNCTION getNode(dadNode DBMS_XMLDOM.DOMNode,
                   nameNode VARCHAR2)
  RETURN DBMS_XMLDOM.DOMNode IS
    nodeList DBMS_XMLDOM.DOMNodeList;
    nodeResult DBMS_XMLDOM.DOMNode;
    nodeAux DBMS_XMLDOM.DOMNode;
  BEGIN
    nodeList := getNodeList(dadNode);

    <<loopAllChildNodes>>
    FOR i IN 0 .. DBMS_XMLDOM.getLength(nodeList)-1 LOOP
      nodeAux := DBMS_XMLDOM.item(nodeList, i);
      --Node with param name
      IF DBMS_XMLDOM.getNodeName(nodeAux) = nameNode THEN
        nodeResult := nodeAux;
      END IF;
    END LOOP loopAllChildNodes;

    RETURN nodeResult;
  END getNode;

  FUNCTION getAttribute(domElement DBMS_XMLDOM.DOMElement,
                        nameAtt VARCHAR2)
  RETURN VARCHAR2 IS
  BEGIN
    RETURN DBMS_XMLDOM.getAttribute(domElement, nameAtt);
  END getAttribute;

  FUNCTION getAttribute(node DBMS_XMLDOM.DOMNode,
                        nameAtt VARCHAR2)
  RETURN VARCHAR2 IS
    attriList DBMS_XMLDOM.DOMNamedNodeMap;
    attriNode DBMS_XMLDOM.DOMNode;
  BEGIN
    attriList := DBMS_XMLDOM.getAttributes(node);

    IF NOT DBMS_XMLDOM.isNull(attriList)
       AND DBMS_XMLDOM.getLength(attriList) > 0 THEN

      attriNode := DBMS_XMLDOM.getNamedItem(attriList, nameAtt);
      IF NOT DBMS_XMLDOM.isNull(attriNode) THEN
        RETURN DBMS_XMLDOM.getNodeValue(attriNode);
      END IF;
    END IF;
    RETURN NULL;
  END getAttribute;

  FUNCTION getName(node DBMS_XMLDOM.DOMNode)
  RETURN VARCHAR2 IS
  BEGIN
    IF NOT DBMS_XMLDOM.isNull(node) THEN
      RETURN DBMS_XMLDOM.getNodeName(node);
    END IF;
    RETURN NULL;
  END getName;

  FUNCTION getValue(node DBMS_XMLDOM.DOMNode)
  RETURN VARCHAR2 IS
    childNode  DBMS_XMLDOM.DOMNode;
  BEGIN
    IF NOT DBMS_XMLDOM.isNull(node) THEN
      childNode  := DBMS_XMLDOM.getFirstChild(node);
      IF NOT DBMS_XMLDOM.isNull(childNode) THEN
        RETURN DBMS_XMLDOM.getNodeValue(childNode);
      END IF;
    END IF;

    RETURN NULL;
  END getValue;

  FUNCTION getValueCDATA(node DBMS_XMLDOM.DOMNode)
  RETURN CLOB IS
    childNode DBMS_XMLDOM.DOMNode;
    cdataNode DBMS_XMLDOM.DOMCharacterData;
    resultData     CLOB;
    buffer   VARCHAR2(32767);
    offset   PLS_INTEGER := 32767;
    position PLS_INTEGER := 0;
    sizeAux NUMBER;

  BEGIN
    IF NOT DBMS_XMLDOM.isNull(node) THEN
      childNode  := DBMS_XMLDOM.getFirstChild(node);

      IF NOT DBMS_XMLDOM.isNull(childNode) THEN
        cdataNode := DBMS_XMLDOM.makeCharacterData(childNode);
        sizeAux := DBMS_XMLDOM.getLength(cdataNode);

        IF sizeAux > 0 THEN
          BEGIN
            LOOP
              buffer := DBMS_XMLDOM.substringData(cdataNode, position, offset);
              position := position + offset;
              resultData := resultData || buffer;
              EXIT WHEN position >= sizeAux;
            END LOOP;
          EXCEPTION
            WHEN OTHERS THEN
              position := 1;
          END;
        END IF;

        RETURN resultData;
      END IF;
    END IF;

    RETURN NULL;
  END getValueCDATA;


  /*
   *******************************************************************************
   ********************* USE XMLTYPE *******************************************
   *******************************************************************************
   */


  FUNCTION domDocumentToXmlType(document DBMS_XMLDOM.DOMDocument)
  RETURN XMLTYPE IS
    xml_out XMLType;
    xml_clob CLOB := EMPTY_CLOB;
  BEGIN
    Dbms_Lob.CreateTemporary(xml_clob, TRUE, Dbms_Lob.SESSION);
    DBMS_XMLDOM.writeToClob(document, xml_clob );

    xml_out := XMLTYPE.CreateXML(xml_clob);
    RETURN xml_out;
  END domDocumentToXmlType;

  FUNCTION xmlTypeToClob(xml XMLTYPE)
  RETURN CLOB IS
  BEGIN
    RETURN xml.getClobVal();
  END xmlTypeToClob;

  FUNCTION clobToXmlType(xml CLOB)
  RETURN XMLTYPE IS
  BEGIN
    RETURN XMLTYPE(xml);
  END clobToXmlType;

  FUNCTION selectToXmlType(selectSql VARCHAR2,
                           nameContainerNode VARCHAR2 := NULL,
                           nameRowNode VARCHAR2 := NULL)
  RETURN XMLTYPE IS
    xml XMLTYPE;
    contextHandle DBMS_XMLGEN.ctxHandle;
  BEGIN
    contextHandle := DBMS_XMLGEN.newContext(selectSql);
    IF nameContainerNode IS NOT NULL THEN
      DBMS_XMLGEN.setRowSetTag(contextHandle, nameContainerNode);
    END IF;
    IF nameRowNode IS NOT NULL THEN
      DBMS_XMLGEN.setRowTag(contextHandle, nameRowNode);
    END IF;
    xml := DBMS_XMLGEN.GETXMLTYPE(contextHandle);
    DBMS_XMLGEN.closeContext(contextHandle);

    RETURN xml;
  END selectToXmlType;

  FUNCTION selectToXmlType(tableName VARCHAR2,
                           whereClause VARCHAR2,
                           nameContainerNode VARCHAR2,
                           nameRowNode VARCHAR2,
                           tColumnsnodes T_COLUMNSNODES,
                           tColumnsattributes T_COLUMNSATTRIBUTES := NULL,
                           tColumnsOrder T_COLUMNSNODES := NULL)
  RETURN XMLTYPE IS
    sqlSelect VARCHAR2(32000);
    xml XMLTYPE;
  BEGIN
    sqlSelect :=
      'SELECT' || CHR(10) ||
      '  XMLElement(' || CHR(10) ||
      '  "'||nameContainerNode||'",' || CHR(10) ||
      '  XMLAgg(' || CHR(10) ||
      '    XMLElement("'||nameRowNode||'",' || CHR(10);

    IF tColumnsattributes IS NOT NULL AND tColumnsattributes.COUNT > 0 THEN
      sqlSelect := sqlSelect || 'XMLAttributes(';
      FOR i IN tColumnsattributes.FIRST..tColumnsattributes.LAST LOOP
        IF tColumnsattributes.EXISTS(i) THEN
          sqlSelect := sqlSelect || 'X.' ||tColumnsattributes(i).NAMECOLUMN || ' AS "' ||
            tColumnsattributes(i).NAMEXML || '"';

          IF i <> tColumnsattributes.LAST THEN
            sqlSelect := sqlSelect || ', ';
          END IF;
        END IF;
      END LOOP;
      sqlSelect := sqlSelect || '),';
    END IF;

    sqlSelect := sqlSelect || 'XMLForest(';
    IF tColumnsnodes IS NOT NULL AND tColumnsnodes.COUNT > 0 THEN
      FOR i IN tColumnsnodes.FIRST..tColumnsnodes.LAST LOOP
        IF tColumnsnodes.EXISTS(i) THEN
          sqlSelect := sqlSelect || 'X.' ||tColumnsnodes(i).NAMECOLUMN || ' AS "' ||
            NVL(tColumnsnodes(i).NAMEXML, tColumnsnodes(i).NAMECOLUMN) || '"';

          IF i <> tColumnsnodes.LAST THEN
            sqlSelect := sqlSelect || ', ';
          END IF;
        END IF;
      END LOOP;
      sqlSelect := sqlSelect || ')' || CHR(10);
    END IF;

    sqlSelect := sqlSelect || ')' || CHR(10);
    IF tColumnsOrder IS NOT NULL AND tColumnsOrder.COUNT > 0 THEN
      sqlSelect := sqlSelect || 'ORDER BY ';
      FOR i IN tColumnsOrder.FIRST..tColumnsOrder.LAST LOOP
        IF tColumnsOrder.EXISTS(i) THEN
          sqlSelect := sqlSelect || 'X.' ||tColumnsOrder(i).NAMECOLUMN;

          IF i <> tColumnsOrder.LAST THEN
            sqlSelect := sqlSelect || ', ';
          END IF;
        END IF;
      END LOOP;
    END IF;

    sqlSelect := sqlSelect || '))' || CHR(10) ||
      'FROM '|| tableName|| ' X' || CHR(10)||
      'WHERE ' || whereClause;
    EXECUTE IMMEDIATE sqlSelect INTO xml;

    RETURN xml;
  END selectToXmlType;

  /**
   * Format indent XML
   * @param xml xml
   * @return
   */
  FUNCTION formatXmlType(xml XMLTYPE,
                         identSize PLS_INTEGER := 2)
  RETURN XMLTYPE IS
    xmlOut XMLTYPE;
    sqlSelect VARCHAR2(32000);
  BEGIN
    sqlSelect := 'SELECT XMLTYPE(XMLSERIALIZE(document :xml AS CLOB INDENT SIZE = '|| identSize||')) FROM DUAL';
    EXECUTE IMMEDIATE sqlSelect INTO xmlOut USING xml;
    RETURN xmlOut;
  END formatXmlType;

  PROCEDURE createNode(xml IN OUT NOCOPY XMLTYPE,
                       pathDadNode VARCHAR2,
                       nameNode VARCHAR2,
                       tNameSpaces T_NAMESPACES := NULL) IS
    nameSpace VARCHAR2(4000);
    endNode VARCHAR2(4000);
    startNode VARCHAR2(4000);
  BEGIN
    --namespace -> is a string literal
    nameSpace := getNameSpaceString(tNameSpaces);

    --if node contain own namespace
    endNode := nameNode;
    IF INSTR(nameNode,CHR(32)) > 0 THEN
      endNode := SUBSTR(nameNode,1,INSTR(nameNode,CHR(32))-1);
    END IF;

    SELECT INSERTCHILDXML(
                xml,
                pathDadNode,
                endNode,
                XMLType('<'||nameNode||'></'||endNode||'>'),
                namespace)
    INTO xml
    FROM DUAL;

  END createNode;

  PROCEDURE createTextNode(xml IN OUT NOCOPY XMLTYPE,
                          pathDadNode VARCHAR2,
                          nameNode VARCHAR2,
                          text VARCHAR2,
                          tNameSpaces T_NAMESPACES := NULL) IS
    nameSpace VARCHAR2(4000);
    endNode VARCHAR2(4000);
  BEGIN
    --namespace -> is a string literal
    nameSpace := getNameSpaceString(tNameSpaces);

    --if node contain own namespace
    endNode := nameNode;
    IF INSTR(nameNode,CHR(32)) > 0 THEN
      endNode := SUBSTR(nameNode,1,INSTR(nameNode,CHR(32))-1);
    END IF;

    SELECT INSERTCHILDXML(
                xml,
                pathDadNode,
                endNode,
                XMLType('<'||nameNode||'>'||text||'</'||endNode||'>'),
                namespace)
    INTO xml
    FROM DUAL;
  END createTextNode;

  PROCEDURE createAttribute(xml IN OUT XMLTYPE,
                            pathNode VARCHAR2,
                            nameAtt VARCHAR2,
                            value VARCHAR2,
                            tNameSpaces T_NAMESPACES := NULL) IS
    nameSpace VARCHAR2(4000);
  BEGIN
    --namespace -> is a string literal
    nameSpace := getNameSpaceString(tNameSpaces);

    SELECT INSERTCHILDXML(
                xml,
                pathNode,
                '@'||nameAtt,
                value,
                namespace)
    INTO xml
    FROM DUAL;
  END createAttribute;

  PROCEDURE addNodeXmltype(xml IN OUT XMLTYPE,
                          pathDadNode VARCHAR2,
                          nameNode VARCHAR2,
                          xmlNode XMLTYPE,
                          tNameSpaces T_NAMESPACES := NULL) IS
    nameSpace VARCHAR2(4000);
  BEGIN
    --namespace -> is a string literal
    nameSpace := getNameSpaceString(tNameSpaces);

    SELECT INSERTCHILDXML(
                xml,
                pathDadNode,
                nameNode,
                xmlNode,
                namespace)
    INTO xml
    FROM DUAL;
  END addNodeXmltype;

  FUNCTION getNode(xml XMLTYPE,
                   pathNode VARCHAR2,
                   tNameSpaces T_NAMESPACES := NULL)
  RETURN XMLTYPE IS
    nodeFinal XMLTYPE;
    nameSpace VARCHAR2(4000);
  BEGIN
    --namespace for EXTRACTVALUE -> is a string literal
    nameSpace := getNameSpaceString(tNameSpaces);

    IF XMLTYPE.existsNode(xml, pathNode, nameSpace) = 1 THEN
      SELECT EXTRACT(xml, pathNode, nameSpace)
      INTO nodeFinal
      FROM DUAL;
    ELSE
      nodeFinal := NULL;
    END IF;
    RETURN nodeFinal;
  END getNode;

  FUNCTION getNodeList(xml XMLTYPE,
                       pathNode VARCHAR2,
                       listColumns T_NODES,
                       tNameSpaces T_NAMESPACES := NULL)
  RETURN SYS_REFCURSOR IS
    sqlSelect VARCHAR2(32000);
    finalCursor SYS_REFCURSOR;
  BEGIN

    IF listColumns.COUNT > 0 THEN
      sqlSelect := 'SELECT '|| CHR(10);

      --add list columns
      FOR i IN listColumns.FIRST..listColumns.LAST LOOP
        IF listColumns.EXISTS(i) THEN
          sqlSelect := sqlSelect || 'X.' || listColumns(i).NAME;
          IF i <> listColumns.LAST THEN
            sqlSelect := sqlSelect || ', ' || CHR(10);
          ELSE
            sqlSelect := sqlSelect || CHR(10);
          END IF;
        END IF;
      END LOOP;

      sqlSelect := sqlSelect || 'FROM XMLTABLE( '|| CHR(10);

      --add name space data
      addNameSpaceXmlTable(sqlSelect, tNameSpaces);

      sqlSelect := sqlSelect ||
        q'(          ')'||pathNode|| q'(')' || CHR(10) ||
        '        PASSING :xml ' ||CHR(10) ||
        '        COLUMNS '||CHR(10);

      --add list columns
      FOR i IN listColumns.FIRST..listColumns.LAST LOOP
        IF listColumns.EXISTS(i) THEN
          sqlSelect := sqlSelect ||
            '          ' || listColumns(i).NAME || ' ' ||  listColumns(i).TYPEDATA ||
            ' PATH '''|| listColumns(i).NAME || '''';
          IF i <> listColumns.LAST THEN
            sqlSelect := sqlSelect || ', ' || CHR(10);
          ELSE
            sqlSelect := sqlSelect || CHR(10);
          END IF;
        END IF;
      END LOOP;

      sqlSelect := sqlSelect || '     ) X';

      OPEN finalCursor FOR sqlSelect USING xml;

    END IF;

    RETURN finalCursor;

  END getNodeList;



  FUNCTION getAttribute(xml XMLTYPE,
                        pathAtt VARCHAR2,
                        tNameSpaces T_NAMESPACES := NULL)
  RETURN VARCHAR2 IS
    valueFinal VARCHAR2(4000);
    nameSpace VARCHAR2(4000);
  BEGIN
    --namespace for EXTRACTVALUE -> is a string literal
    nameSpace := getNameSpaceString(tNameSpaces);

    IF XMLTYPE.existsNode(xml, pathAtt, nameSpace) = 1 THEN
      SELECT EXTRACTVALUE(xml, pathAtt, nameSpace)
      INTO valueFinal
      FROM DUAL;
    ELSE
      valueFinal := NULL;
    END IF;

    RETURN valueFinal;
  END getAttribute;

  FUNCTION getValue(xml XMLTYPE,
                    pathNode VARCHAR2,
                    tNameSpaces T_NAMESPACES := NULL)
  RETURN VARCHAR2 IS
    valueFinal VARCHAR2(4000);
    nameSpace VARCHAR2(4000);
    pathNodeFinal VARCHAR2(4000);
  BEGIN
    --namespace for EXTRACTVALUE -> is a string literal
    nameSpace := getNameSpaceString(tNameSpaces);

    pathNodeFinal := pathNode;
    IF INSTR(pathNodeFinal, '/text()') = 0 THEN
      pathNodeFinal := pathNodeFinal || '/text()';
    END IF;

    IF XMLTYPE.existsNode(xml, pathNodeFinal, nameSpace) = 1 THEN
      SELECT EXTRACTVALUE(xml, pathNodeFinal, nameSpace)
      INTO valueFinal
      FROM DUAL;
    ELSE
      valueFinal := NULL;
    END IF;

    RETURN valueFinal;
  END getValue;

  FUNCTION getValueLarge(xml XMLTYPE,
                    pathFatherNode VARCHAR2,
                    nameNode VARCHAR2,
                    tNameSpaces T_NAMESPACES := NULL)
  RETURN CLOB IS
    sqlSelect VARCHAR2(4000);
    resultaData CLOB;
  BEGIN
    sqlSelect :=
      'SELECT X.COLUM_RESULT '|| CHR(10) ||
      'FROM XMLTABLE( '|| CHR(10);

    --add name space data
    addNameSpaceXmlTable(sqlSelect, tNameSpaces);

    sqlSelect := sqlSelect ||
      q'(          ')'||pathFatherNode|| q'(')' || CHR(10) ||
      '        PASSING :xml ' ||CHR(10) ||
      '        COLUMNS '||CHR(10) ||
      q'(          COLUM_RESULT CLOB PATH ')'|| nameNode || q'(' )' ||CHR(10) ||
      '     ) X';

    EXECUTE IMMEDIATE sqlSelect INTO resultaData USING xml;

    RETURN resultaData;

  END getValueLarge;

  PROCEDURE updateTextNode(xml IN OUT NOCOPY XMLTYPE,
                          pathNode VARCHAR2,
                          text VARCHAR2,
                          tNameSpaces T_NAMESPACES := NULL) IS
    nameSpace VARCHAR2(4000);
    pathNodeFinal VARCHAR2(4000);
  BEGIN
    --namespace for EXTRACTVALUE -> is a string literal
    nameSpace := getNameSpaceString(tNameSpaces);

    pathNodeFinal := pathNode;
    IF INSTR(pathNodeFinal, '/text()') = 0 THEN
      pathNodeFinal := pathNodeFinal || '/text()';
    END IF;

    IF XMLTYPE.existsNode(xml, pathNodeFinal, nameSpace) = 1 THEN
      SELECT UPDATEXML(xml, pathNodeFinal, text, nameSpace)
      INTO xml
      FROM DUAL;
    END IF;

  END updateTextNode;



END UTILXML;
/
SHOW ERRORS
