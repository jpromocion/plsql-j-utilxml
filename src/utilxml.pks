/**
 * Util package handle xml - plsql
 * Autor: jpromocion (https://github.com/jpromocion/plsql-j-utilxml)
 * License: GNU General Public License v3.0
 */
CREATE OR REPLACE PACKAGE UTILXML AS

  --Type for save pair: namespace / value namespace
  TYPE T_NAMESPACE IS RECORD (
    PREFIX VARCHAR(500), --Example: xmlns of xmlns:a="http://a/"
    NAMESPACE VARCHAR(500), --Example: a of xmlns:a="http://a/"
    VALUE    VARCHAR(4000) --Example: http://a/ of xmlns:a="http://a/"
  );

  --Table save name spaces of xml
  TYPE T_NAMESPACES IS TABLE OF T_NAMESPACE;

  --Type for save pair: node xml / type
  TYPE T_NODE IS RECORD (
    NAME VARCHAR(30),
    TYPEDATA VARCHAR(500) := 'VARCHAR2(4000)'
  );

  --Table save list child nodes for extract value
  TYPE T_NODES IS TABLE OF T_NODE INDEX BY PLS_INTEGER;

  --Type data table for represent xml
  TYPE T_DATATABLE IS RECORD (
    NAMECOLUMN VARCHAR(30),
    NAMEXML VARCHAR(500)
  );

  --Table save list columns of table for represent xml like node
  TYPE T_COLUMNSNODES IS TABLE OF T_DATATABLE;

  --Table save list columns of table for represent xml like attribute
  TYPE T_COLUMNSATTRIBUTES IS TABLE OF T_DATATABLE;

  /*
   *******************************************************************************
   ********************* GENERAL USE *********************************
   *******************************************************************************
   */

  /**
   * Data escaped to XML equivalent
   * @param string String to escaped
   * @return String escaped
   */
  FUNCTION escapedStringXML(string VARCHAR2)
  RETURN VARCHAR2;

  /**
   * Data escaped to XML equivalent
   * NOTE: Overload with CLOB
   * @param string String to escaped
   * @return String escaped
   */
  FUNCTION escapedStringXML(string CLOB)
  RETURN CLOB;

  /**
   * Data unescaped from XML equivalent
   * @param string String escaped
   * @return String unescaped
   */
  FUNCTION unEscapedStringXML(string VARCHAR2)
  RETURN VARCHAR2;

  /**
   * Data unescaped from XML equivalent
   * NOTE: Overload with CLOB
   * @param string String escaped
   * @return String unescaped
   */
  FUNCTION unEscapedStringXML(string CLOB)
  RETURN CLOB;


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
   RETURN DBMS_XMLDOM.DOMDocument;

  /**
   * Parse Xml in string to DOMDocument xml
   * @param xml String xml
   * @return new DOMDocument xml
   */
  FUNCTION stringToDOMDocument(xml VARCHAR2)
  RETURN DBMS_XMLDOM.DOMDocument;


  /**
   * Parse Xml in clob string to DOMDocument xml
   * @param xml Clob string xml
   * @return new DOMDocument xml
   */
  FUNCTION stringToDOMDocument(xml CLOB)
  RETURN DBMS_XMLDOM.DOMDocument;

  /**
   * Create new Node in xml
   * @param DOMDocument xml
   * @param dadNode Father node
   * @param nameNode Name new node
   * @return
   */
  FUNCTION createNode(document DBMS_XMLDOM.DOMDocument,
                      dadNode DBMS_XMLDOM.DOMNode,
                      nameNode VARCHAR2)
  RETURN DBMS_XMLDOM.DOMNode;

  /**
   * Create new Node in xml with text value
   * @param document DOMDocument xml
   * @param dadNode Father node
   * @param nameNode Name new node
   * @param text Text value
   * @return
   */
  FUNCTION createTextNode(document DBMS_XMLDOM.DOMDocument,
                          dadNode DBMS_XMLDOM.DOMNode,
                          nameNode VARCHAR2,
                          text VARCHAR2)
  RETURN DBMS_XMLDOM.DOMNode;


  /**
   * Create atrribute in node
   * @param node Node where add attribute
   * @param name Attribute name
   * @param value
   * @return
   */
  PROCEDURE createAttribute(node DBMS_XMLDOM.DOMNode,
                            name VARCHAR2,
                            value VARCHAR2);

  /**
   * Add a node of structure XMLTYPE like child node in a DomDOcument xml
   * @param document DOMDocument xml
   * @param dadNode Father node
   * @param xmlNode Will be child node
   * @return Child node create
   */
  FUNCTION addNodeXmltype(xml DBMS_XMLDOM.DOMDocument,
                          dadNode  DBMS_XMLDOM.DOMNode,
                          xmlNode XMLTYPE)
  RETURN DBMS_XMLDOM.DOMNode;


  /**
   * Return root element of DOMDocument xml
   * @param document DOMDocument xml
   * @return Root element
   */
  FUNCTION getRoot(document DBMS_XMLDOM.DOMDocument)
  RETURN DBMS_XMLDOM.DOMElement;

  /**
   * Return a node list with parameter name child of DOMDocument xml
   * @param document DOMDocument xml
   * @param nameNode Node name
   * @return List child nodes
   */
  FUNCTION getNodeList(document DBMS_XMLDOM.DOMDocument,
                       nameNode VARCHAR2)
  RETURN DBMS_XMLDOM.DOMNodeList;

  /**
   * Return a node list with all childs of node
   * @param document node
   * @return List child nodes
   */
  FUNCTION getNodeList(dadNode DBMS_XMLDOM.DOMNode)
  RETURN DBMS_XMLDOM.DOMNodeList;

  /**
   * Get a node with parameter name, search in DOMDocument.
   * @param document DOMDocument xml
   * @param nameNode Node name
   * @return Node DOMNode type. Many nodes... return first
   */
  FUNCTION getNode(document DBMS_XMLDOM.DOMDocument,
                   nameNode VARCHAR2)
  RETURN DBMS_XMLDOM.DOMNode;

  /**
   * Get a node with parameter name, search in DOMNode father.
   * @param dadNode DOMNode father
   * @param nameNode Node name
   * @return Node DOMNode type. Many nodes... return first
   */
  FUNCTION getNode(dadNode DBMS_XMLDOM.DOMNode,
                   nameNode VARCHAR2)
  RETURN DBMS_XMLDOM.DOMNode;

  /**
   * Return value attribute of node type  DOMElement
   * @param domElement node
   * @param nameAtt Attribute name
   * @return Value of attribute
   */
  FUNCTION getAttribute(domElement DBMS_XMLDOM.DOMElement,
                        nameAtt VARCHAR2)
  RETURN VARCHAR2;
  /**
   * Return value attribute of node type DOMNode
   * @param node node
   * @param nameAtt Attribute name
   * @return Value of attribute
   */
  FUNCTION getAttribute(node DBMS_XMLDOM.DOMNode,
                        nameAtt VARCHAR2)
  RETURN VARCHAR2;
  /**
   * Return name of node
   * @param node node
   * @return Name of node
   */
  FUNCTION getName(node DBMS_XMLDOM.DOMNode)
  RETURN VARCHAR2;

  /**
   * Return value of DOMNode like string
   * @param node DOMNode object
   * @return Value of node
   */
  FUNCTION getValue(node DBMS_XMLDOM.DOMNode)
  RETURN VARCHAR2;
  /**
   * Return value of DOMNode with value in <![CDATA[...]]> like CLOB
   * @param node DOMNode object
   * @return Valur of node
   */
  FUNCTION getValueCDATA(node DBMS_XMLDOM.DOMNode)
  RETURN CLOB;

  /*
   *******************************************************************************
   ********************* USE XMLTYPE *******************************************
   *******************************************************************************
   */

  /**
   * Return XMLTYPE for a DOMDocument xml
   * @param document
   * @return
   */
  FUNCTION domDocumentToXmlType(document DBMS_XMLDOM.DOMDocument)
  RETURN XMLTYPE;
  /**
   * Return CLOB for a XMLTYPE xml
   * @param xml
   * @return
   */
  FUNCTION xmlTypeToClob(xml XMLTYPE)
  RETURN CLOB;

  /**
   * Return XMLTYPE for a CLOB xml
   * @param xml
   * @return
   */
  FUNCTION clobToXmlType(xml CLOB)
  RETURN XMLTYPE;

  /**
   * Return XMLTYPE represent value of select
   * @param selectSql Select SQL return values
   * @param nameContainerNode name root node. IF not specify -> ROWSET
   * @param nameRowNode name node for each row. IF not specify -> ROW
   * @return xml represent values of select
   */
  FUNCTION selectToXmlType(selectSql VARCHAR2,
                           nameContainerNode VARCHAR2 := NULL,
                           nameRowNode VARCHAR2 := NULL)
  RETURN XMLTYPE;

  /**
   * Return XMLTYPE represent value table's rows search
   * @param tableName Name table search
   * @param whereClause Where clause
   * @param nameContainerNode name root node. IF not specify -> ROWSET
   * @param nameRowNode name node for each row. IF not specify -> ROW*
   * @param tColumnsnodes Columns of table -> xml nodes
   * @param tColumnsattributes Columns of table -> xml attributes
   * @param tColumnsOrder Specific order columns
   * @return xml represent values of table's row
   */
  FUNCTION selectToXmlType(tableName VARCHAR2,
                           whereClause VARCHAR2,
                           nameContainerNode VARCHAR2,
                           nameRowNode VARCHAR2,
                           tColumnsnodes T_COLUMNSNODES,
                           tColumnsattributes T_COLUMNSATTRIBUTES := NULL,
                           tColumnsOrder T_COLUMNSNODES := NULL)
  RETURN XMLTYPE;

  /**
   * Format indent XML
   * @param xml xml
   * @param identSize Size of ident. Default 2
   * @return
   */
  FUNCTION formatXmlType(xml XMLTYPE,
                         identSize PLS_INTEGER := 2)
  RETURN XMLTYPE;

  /**
   * Create new Node in xml
   * @param xml xml source and destination
   * @param pathDadNode  Name and path for father node -> XQuery.
   *      -Example node: "/n:NODE_A/NODE_B/NODE_C"
   * @param nameNode Name new node
   * @param tNameSpaces Table with all necessary namespace. If not namespace -> NULL. Default NULL.*
   */
  PROCEDURE createNode(xml IN OUT NOCOPY XMLTYPE,
                       pathDadNode VARCHAR2,
                       nameNode VARCHAR2,
                       tNameSpaces T_NAMESPACES := NULL);

   /**
    * Create new Node in xml with text value
    * @param xml xml source and destination
    * @param pathDadNode  Name and path for father node -> XQuery.
    *      -Example node: "/n:NODE_A/NODE_B/NODE_C"
    * @param nameNode Name new node
    * @param text Text value
    * @param tNameSpaces Table with all necessary namespace. If not namespace -> NULL. Default NULL.*
    */
   PROCEDURE createTextNode(xml IN OUT NOCOPY XMLTYPE,
                           pathDadNode VARCHAR2,
                           nameNode VARCHAR2,
                           text VARCHAR2,
                           tNameSpaces T_NAMESPACES := NULL);

   /**
    * Create atrribute in node
    * @param xml xml source and destination
    * @param pathNode  Name and path for node -> XQuery.
    *      -Example node: "/n:NODE_A/NODE_B/NODE_C"
    * @param nameAtt Name new attribute
    * @param xmlNode Will be child node
    * @param value
    * @param tNameSpaces Table with all necessary namespace. If not namespace -> NULL. Default NULL.
    */
   PROCEDURE createAttribute(xml IN OUT NOCOPY XMLTYPE,
                             pathNode VARCHAR2,
                             nameAtt VARCHAR2,
                             value VARCHAR2,
                             tNameSpaces T_NAMESPACES := NULL);

   /**
    * Add a node of structure XMLTYPE like child node in a XMLTYPE xml
    * @param xml xml source and destination
    * @param pathDadNode  Name and path for father node -> XQuery.
    *      -Example node: "/n:NODE_A/NODE_B/NODE_C"
    * @param nameNode Name new root node of child node
    * @param xmlNode Will be child node
    * @param tNameSpaces Table with all necessary namespace. If not namespace -> NULL. Default NULL.
    */
   PROCEDURE addNodeXmltype(xml IN OUT NOCOPY XMLTYPE,
                            pathDadNode VARCHAR2,
                            nameNode VARCHAR2,
                            xmlNode XMLTYPE,
                            tNameSpaces T_NAMESPACES := NULL);

  /**
   * Get a node for xmltype
   * @param xml xml
   * @param pathNode Name and path for node -> XQuery.
   *      -Example node: "/n:NODE_A/NODE_B/NODE_C"
   * @param tNameSpaces Table with all necessary namespace. If not namespace -> NULL. Default NULL.*
   * @return Node XMLType
   */
  FUNCTION getNode(xml XMLTYPE,
                   pathNode VARCHAR2,
                   tNameSpaces T_NAMESPACES := NULL)
  RETURN XMLTYPE;

  /**
   * Return a cursor with select with all contain for node or nodes
   * @param xml xml
   * @param pathNode Name and path for node -> XQuery.
   *      -Example node: "/n:NODE_A/NODE_B/NODE_C"
   * @param listColumns List of name and type nodes which return as columns
   * @param tNameSpaces Table with all necessary namespace. If not namespace -> NULL. Default NULL.*
   * @return Cursor open ready for loop. Many nodes -> many rows. Mapping columns to the RECORD correct
   */
  FUNCTION getNodeList(xml XMLTYPE,
                       pathNode VARCHAR2,
                       listColumns T_NODES,
                       tNameSpaces T_NAMESPACES := NULL)
  RETURN SYS_REFCURSOR;

  /**
   * Return value of attribute like string for xmltype
   * @param xml xml
   * @param pathAtt Name and path for attribute value -> XQuery.
   *      -Example value attribute: "//n:NODE_C/@att_1"
   * @param tNameSpaces Table with all necessary namespace. If not namespace -> NULL. Default NULL.
   * @return Value of attribute
   */
  FUNCTION getAttribute(xml XMLTYPE,
                        pathAtt VARCHAR2,
                        tNameSpaces T_NAMESPACES := NULL)
  RETURN VARCHAR2;

  /**
   * Return value of node like string for xmltype
   * @param xml xml
   * @param pathNode Name and path for node value -> XQuery.
   *      -Example value node: "/n:NODE_A/NODE_B/NODE_C/text()" or " "/n:NODE_A/NODE_B/NODE_C"
   *      (/text() will be automatically add)
   * @param tNameSpaces Table with all necessary namespace. If not namespace -> NULL. Default NULL.
   * @return Value of node
   */
  FUNCTION getValue(xml XMLTYPE,
                    pathNode VARCHAR2,
                    tNameSpaces T_NAMESPACES := NULL)
  RETURN VARCHAR2;

  /**
   * Return value of node like CLOB (for large string in node) for xmltype
   * @param xml xml
   * @param pathFatherNode Name and path for node father -> XQuery.
   * @param nameNode name object node.
   * @param tNameSpaces Table with all necessary namespace. If not namespace -> NULL. Default NULL.
   * @return Value of node
   */
  FUNCTION getValueLarge(xml XMLTYPE,
                         pathFatherNode VARCHAR2,
                         nameNode VARCHAR2,
                         tNameSpaces T_NAMESPACES := NULL)
  RETURN CLOB;

  /**
   * Update text value of node exists
   * @param xml xml source and destination
   * @param pathDadNode  Name and path for node -> XQuery.
   *      -Example node: "/n:NODE_A/NODE_B/NODE_C"
   * @param text New text value
   * @param tNameSpaces Table with all necessary namespace. If not namespace -> NULL. Default NULL.*
   */
  PROCEDURE updateTextNode(xml IN OUT NOCOPY XMLTYPE,
                          pathNode VARCHAR2,
                          text VARCHAR2,
                          tNameSpaces T_NAMESPACES := NULL);





END UTILXML;
/
SHOW ERRORS
