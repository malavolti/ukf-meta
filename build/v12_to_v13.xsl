<?xml version="1.0" encoding="UTF-8"?>
<!--

	v12_to_v13.xsl
	
	XSL stylesheet converting a Shibboleth 1.2 sites file into the equivalent for
	Shibboleth 1.3, which is based on the SAML 1.1 profile of the SAML 2.0
	metadata format.  No attempt is made to incorporate the separate trust
	data used by Shibboleth 1.2.
	
	Author: Ian A. Young <ian@iay.org.uk>

-->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
	xmlns:shib="urn:mace:shibboleth:1.0"
	xmlns:shibmeta="urn:mace:shibboleth:metadata:1.0"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
	exclude-result-prefixes="shib">

	<!--Force UTF-8 encoding for the output.-->
	<xsl:output omit-xml-declaration="no" method="xml" encoding="UTF-8" indent="yes"/>

	<!--
		SiteGroup is the root element for the sites file.  The corresponding element in the new format file
		is an EntitiesDescriptor.
	-->
	<xsl:template match="shib:SiteGroup">
		<EntitiesDescriptor Name="{@Name}">
			<xsl:attribute name="xsi:schemaLocation">
				<xsl:text>urn:oasis:names:tc:SAML:2.0:metadata sstc-saml-schema-metadata-2.0.xsd </xsl:text>
				<xsl:text>urn:mace:shibboleth:metadata:1.0 shibboleth-metadata-1.0.xsd </xsl:text>
				<xsl:text>http://www.w3.org/2000/09/xmldsig# xmldsig-core-schema.xsd</xsl:text>
			</xsl:attribute>
			<!--
				Pass through text blocks and comments, and any shib elements.
				These may be: OriginSite, DestinationSite or nested SiteGroup.
			-->
			<xsl:apply-templates select="text()|comment()|shib:*"/>
		</EntitiesDescriptor>
	</xsl:template>

	<!--
		Map OriginSite to an EntityDescriptor with a particular format.
	-->
	<xsl:template match="shib:OriginSite">
		<EntityDescriptor entityID="{@Name}">
			<!--
				Copy through comments and text blocks at the start of the output element.
				This means we don't lose comments, but there is no way to guarantee they will
				come out "in the right place".
			-->
			<xsl:apply-templates select="text()|comment()"/>
			<!--
				Map HandleService and AttributeAuthority.  We need to pass in the (possibly empty)
				set of Domain elements as a parameter.
			-->
			<xsl:apply-templates select="shib:HandleService|shib:AttributeAuthority">
				<xsl:with-param name="Domain" select="shib:Domain"/>
			</xsl:apply-templates>
			<xsl:call-template name="Alias"/>
			<xsl:apply-templates select="shib:Contact"/>
		</EntityDescriptor>
	</xsl:template>
	
	<!--
		Map HandleService to IDPSSODescriptor.
	-->
	<xsl:template match="shib:HandleService">
		<xsl:param name="Domain"/>
		<IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:1.1:protocol urn:mace:shibboleth:1.0">
			<!--
				Extensions appears iff there is something to put in it.
			-->
			<xsl:if test="boolean($Domain)">
				<Extensions>
					<xsl:apply-templates select="$Domain"/>
				</Extensions>
			</xsl:if>
			<KeyDescriptor use="signing">
				<ds:KeyInfo>
					<ds:KeyName>
						<xsl:value-of select="@Name"/>
					</ds:KeyName>
				</ds:KeyInfo>
			</KeyDescriptor>
			<SingleSignOnService Binding="urn:mace:shibboleth:1.0:profiles:AuthnRequest"
				Location="{@Location}"/>
		</IDPSSODescriptor>
	</xsl:template>

	<!--
		Map AttributeAuthority to AttributeAuthorityDescriptor.
	-->
	<xsl:template match="shib:AttributeAuthority">
		<xsl:param name="Domain"/>
		<AttributeAuthorityDescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:1.1:protocol">
			<!--
				Extensions appears iff there is something to put in it.
			-->
			<xsl:if test="boolean($Domain)">
				<Extensions>
					<xsl:apply-templates select="$Domain"/>
				</Extensions>
			</xsl:if>
			<AttributeService Binding="urn:oasis:names:tc:SAML:1.0:bindings:SOAP-binding"
				Location="{@Location}"/>
		</AttributeAuthorityDescriptor>
	</xsl:template>
	
	<!--
		Map Domain to a Scope extension.
	-->
	<xsl:template match="shib:Domain">
		<shibmeta:Scope>
			<xsl:apply-templates select="@regexp"/>
			<xsl:value-of select="."/>
		</shibmeta:Scope>
	</xsl:template>
	
	<!--
		Map DestinationSite to an EntityDescriptor with a particular format.
	-->
	<xsl:template match="shib:DestinationSite">
		<EntityDescriptor entityID="{@Name}">
			<!--
				Copy through comments and text blocks at the start of the output element.
				This means we don't lose comments, but there is no way to guarantee they will
				come out "in the right place".
			-->
			<xsl:apply-templates select="text()|comment()"/>
			<!--
				Generate IDPSSODescriptor.
			-->
			<SPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:1.1:protocol">
				<!--
					Map @ErrorURL (if present) to @errorURL
				-->
				<xsl:apply-templates select="@ErrorURL"/>
				<!--
					Map AttributeRequester elements to KeyDescriptor elements.
				-->
				<xsl:apply-templates select="shib:AttributeRequester"/>
				<!--
					Map the AssertionConsumerServiceURL elements to
					AssertionConsumerService elements.  The latter require unique
					integer indices, so do this by looping over them and using
					position in the loop to generate each index.
				-->
				<xsl:for-each select="shib:AssertionConsumerServiceURL">
					<xsl:apply-templates select=".">
						<xsl:with-param name="index" select="position()-1"/>
					</xsl:apply-templates>
				</xsl:for-each>
			</SPSSODescriptor>
			<xsl:call-template name="Alias"/>
			<xsl:apply-templates select="shib:Contact"/>
		</EntityDescriptor>
	</xsl:template>

	<!--
		Map @ErrorURL to @errorURL
	-->
	<xsl:template match="@ErrorURL">
		<xsl:attribute name="errorURL"><xsl:value-of select="."/></xsl:attribute>
	</xsl:template>

	<!--
		Map AttributeRequester to KeyDescriptor.
	-->
	<xsl:template match="shib:AttributeRequester">
		<KeyDescriptor>
			<ds:KeyInfo>
				<ds:KeyName>
					<xsl:value-of select="@Name"/>
				</ds:KeyName>
			</ds:KeyInfo>
		</KeyDescriptor>
	</xsl:template>

	<!--
		Map AssertionConsumerServiceURL to AssertionConsumerService.
	-->
	<xsl:template match="shib:AssertionConsumerServiceURL">
		<xsl:param name="index"/>
		<AssertionConsumerService index="{$index}"
			Binding="urn:oasis:names:tc:SAML:1.0:profiles:browser-post" Location="{@Location}"
		/>
	</xsl:template>

	<!--
		Named template to map a set of Alias elements to a corresponding Organization.
	-->
	<xsl:template name="Alias">
		<xsl:if test="boolean(shib:Alias)">
			<Organization>
				<xsl:apply-templates select="shib:Alias" mode="OrganizationName"/>
				<xsl:apply-templates select="shib:Alias" mode="OrganizationDisplayName"/>
				<xsl:apply-templates select="shib:Alias" mode="OrganizationURL"/>
			</Organization>
		</xsl:if>
	</xsl:template>

	<!--
		Map Alias to OrganizationName
	-->
	<xsl:template match="shib:Alias" mode="OrganizationName">
		<OrganizationName>
			<xsl:call-template name="copyXmlLang"/>
			<xsl:value-of select="."/>
		</OrganizationName>
	</xsl:template>

	<!--
		Map Alias to OrganizationDisplayName
	-->
	<xsl:template match="shib:Alias" mode="OrganizationDisplayName">
		<OrganizationDisplayName>
			<xsl:call-template name="copyXmlLang"/>
			<xsl:value-of select="."/>
		</OrganizationDisplayName>
	</xsl:template>

	<!--
		Map Alias to OrganizationURL
	-->
	<xsl:template match="shib:Alias" mode="OrganizationURL">
		<OrganizationURL>
			<xsl:call-template name="copyXmlLang"/>
			<!-- there is nothing to map, but the URL is mandatory -->
			<xsl:text>http://www.example.com/</xsl:text>
		</OrganizationURL>
	</xsl:template>

	<!--
		Copy an xml:lang attribute, or default to "en" if none present.
	-->
	<xsl:template name="copyXmlLang">
		<xsl:if test="boolean(@xml:lang)">
			<xsl:attribute name="xml:lang"><xsl:value-of select="@xml:lang"/></xsl:attribute>
		</xsl:if>
		<xsl:if test="not(boolean(@xml:lang))">
			<xsl:attribute name="xml:lang">en</xsl:attribute>
		</xsl:if>
	</xsl:template>

	<!--
		Map Contact to ContactPerson
	-->
	<xsl:template match="shib:Contact">
		<ContactPerson contactType="{@Type}">
			<!--
				There is no real mapping for the Name attribute, so we rather arbitrarily
				dump that into GivenName rather than trying to split it into a GivenName and
				a SurName or something complicated like that.
			-->
			<GivenName>
				<xsl:value-of select="@Name"/>
			</GivenName>
			<!--
				E-mail address, but only if it was present in the original.
			-->
			<xsl:apply-templates select="@Email" mode="Contact"/>
		</ContactPerson>
	</xsl:template>

	<!--
		E-mail address for Contact
	-->
	<xsl:template match="@Email" mode="Contact">
		<EmailAddress>
			<!-- add a "mailto:" to make an e-mail address into a valid URI. -->
			<xsl:text>mailto:</xsl:text>
			<xsl:value-of select="."/>
		</EmailAddress>
	</xsl:template>

	<!--
		By default, copy referenced attributes through unchanged.
	-->
	<xsl:template match="@*">
		<xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
	</xsl:template>

	<!--
		By default, copy comments and text nodes through to the output unchanged.
	-->
	<xsl:template match="text()|comment()">
		<xsl:copy/>
	</xsl:template>

</xsl:stylesheet>
