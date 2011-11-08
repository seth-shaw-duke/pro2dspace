<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:template match="/DISS_submission">
    <dublin_core>
      <dcvalue element="contributor" qualifier="author">
        <xsl:apply-templates select="DISS_authorship/DISS_author/DISS_name"/>
      </dcvalue>
      <dcvalue element="title">
        <xsl:value-of select="DISS_description/DISS_title"/>
      </dcvalue>
      <dcvalue element="date" qualifier="issued">
        <xsl:value-of select="DISS_description/DISS_dates/DISS_comp_date"/>
      </dcvalue>
      <dcvalue element="department">
        <xsl:apply-templates select="DISS_description/DISS_institution/DISS_inst_contact"/>
      </dcvalue>
      <xsl:for-each select="DISS_description/DISS_advisor">
        <dcvalue element="contributor" qualifier="advisor">
          <xsl:apply-templates select="DISS_name"/>
        </dcvalue>
      </xsl:for-each>
      <xsl:for-each select="DISS_description/DISS_categorization/DISS_category/DISS_cat_desc">
        <dcvalue element="subject">
          <xsl:value-of select="node()"/>
        </dcvalue>
      </xsl:for-each>
      <xsl:apply-templates select="DISS_description/DISS_categorization/DISS_keyword"/>
      <dcvalue element="description" qualifier="abstract">
        <xsl:apply-templates select="DISS_content/DISS_abstract"/>
      </dcvalue>
      <xsl:variable name="type_code" select="DISS_description/@type"/>
      <xsl:choose>
        <xsl:when test="$type_code='doctoral'">
          <dcvalue element="description">Dissertation</dcvalue>
          <dcvalue element="type">Dissertation</dcvalue>
        </xsl:when>
        <xsl:when test="$type_code='masters'">
          <dcvalue element="description">Thesis</dcvalue>
          <dcvalue element="type">Thesis</dcvalue>
        </xsl:when>
      </xsl:choose>
    </dublin_core>
  </xsl:template>
  <xsl:template match="DISS_abstract">
    <xsl:for-each select="DISS_para">
      <xsl:text>&lt;p&gt;</xsl:text>
      <xsl:value-of select="node()"/>
      <xsl:text>&lt;/p&gt;</xsl:text>
    </xsl:for-each>
  </xsl:template>
  <xsl:template match="DISS_name">
    <xsl:value-of select="DISS_surname"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="DISS_fname"/>
    <xsl:if test="not(DISS_middle = '')">
      <xsl:text> </xsl:text>
      <xsl:value-of select="DISS_middle"/>
    </xsl:if>
    <xsl:if test="not(DISS_suffix = '')">
      <xsl:text> </xsl:text>
      <xsl:value-of select="DISS_suffix"/>
    </xsl:if>
  </xsl:template>
  <xsl:template match="DISS_keyword">
    <xsl:choose>
      <xsl:when test="string(.)">
        <xsl:call-template name="output-tokens">
          <xsl:with-param name="list">
            <xsl:value-of select="text()"/>
          </xsl:with-param>
          <xsl:with-param name="delimiter">,</xsl:with-param>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="output-tokens">
    <xsl:param name="list"/>
    <xsl:param name="delimiter"/>
    <xsl:variable name="newlist">
      <xsl:choose>
        <xsl:when test="contains($list, $delimiter)">
          <xsl:value-of select="normalize-space($list)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat(normalize-space($list), $delimiter)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="first" select="substring-before($newlist, $delimiter)"/>
    <xsl:variable name="remaining" select="substring-after($newlist, $delimiter)"/>
    <dcvalue element="subject">
      <xsl:value-of select="$first"/>
    </dcvalue>
    <xsl:if test="$remaining">
      <xsl:call-template name="output-tokens">
        <xsl:with-param name="list" select="$remaining"/>
        <xsl:with-param name="delimiter">
          <xsl:value-of select="$delimiter"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
