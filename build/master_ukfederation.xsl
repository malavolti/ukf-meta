<?xml version="1.0" encoding="UTF-8"?>
<!--

	master_ukfederation.xsl
	
	XSL stylesheet that takes a SAML 2.0 metadata master file containing
	a trust fabric and optional entities, and makes a UK Federation
	master file by tweaking appropriately and inserting the combined
	entities file.
	
	Author: Ian A. Young <ian@iay.org.uk>

	$Id: master_ukfederation.xsl,v 1.1 2006/10/09 19:16:00 iay Exp $
-->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
	xmlns:shibmeta="urn:mace:shibboleth:metadata:1.0"
	xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:wayf="http://sdss.ac.uk/2006/06/WAYF"
	xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
	exclude-result-prefixes="wayf">

	<!--
		Version information for this file.  Remember to peel off the dollar signs
		before dropping the text into another versioned file.
	-->
	<xsl:param name="cvsId">$Id: master_ukfederation.xsl,v 1.1 2006/10/09 19:16:00 iay Exp $</xsl:param>

	<!--
		Add a comment to the start of the output file.
	-->
	<xsl:template match="/">
		<xsl:comment>
			<xsl:text>&#10;&#9;***DO NOT EDIT THIS FILE***&#10;&#10;</xsl:text>
			<xsl:text>&#9;Generated by:&#10;&#10;&#9;</xsl:text>
			<xsl:value-of select="substring-before(substring-after($cvsId, ': '), '$')"/>
			<xsl:text>&#10;</xsl:text>
		</xsl:comment>
		<xsl:apply-templates/>
	</xsl:template>

	<!--Force UTF-8 encoding for the output.-->
	<xsl:output omit-xml-declaration="no" method="xml" encoding="UTF-8" indent="yes"/>

	<!--
		Root EntitiesDescriptor element.
		
		Copy all attributes and nested elements to the output, then
		insert the entities from the entities file at the end.
	-->
	<xsl:template match="/md:EntitiesDescriptor">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>
			<xsl:apply-templates select="document('../xml/entities.xml')/*/md:EntityDescriptor"/>
		</xsl:copy>
	</xsl:template>

	<!--
		Tweak the federation URI.
	-->
	<xsl:template match="@Name[parent::md:EntitiesDescriptor]">
		<xsl:attribute name="Name">http://ukfederation.org.uk</xsl:attribute>
	</xsl:template>
	
	<!--
		Drop any explicit xsi:schemaLocation attributes from imported entity fragments.
	-->
	<xsl:template match="@xsi:schemaLocation[parent::md:EntityDescriptor]">
		<!-- nothing -->
	</xsl:template>
	
	<!--By default, copy text blocks, comments and attributes unchanged.-->
	<xsl:template match="text()|comment()|@*">
		<xsl:copy/>
	</xsl:template>
	
	<!--By default, copy all elements from the input to the output, along with their attributes and contents.-->
	<xsl:template match="*">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>
