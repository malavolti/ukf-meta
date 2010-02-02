<?xml version="1.0" encoding="UTF-8"?>
<!--

	import.xsl
	
	XSL stylesheet that takes a SAML 2 metadata file containing
	an EntityDescriptor from some other system (e.g., metadata
	generated automatically by a Shibboleth installation) and
	adjusts it towards the standard used for a UK federation
	metadata repository fragment file.
	
	Assumptions:
	
	* the output will have oXygen's "format and indent" applied
	via the Eclipse plug-in.  This means that output format doesn't
	need to be particularly precise.
	
	* the metadata comes from a UK federation member
	
	* the metadata most likely represents a Shibboleth 2.x entity
	
	
	Author: Ian A. Young <ian@iay.org.uk>

-->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"

	xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
	xmlns:idpdisc="urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol"
	xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
	xmlns:shibmd="urn:mace:shibboleth:metadata:1.0"
	xmlns:ukfedlabel="http://ukfederation.org.uk/2006/11/label"
	
	xmlns:mdxDates="xalan://uk.ac.sdss.xalan.md.Dates"
	xmlns:mdxTextUtils="xalan://uk.ac.sdss.xalan.md.TextUtils"
	extension-element-prefixes="mdxDates mdxTextUtils"

	xmlns:xalan="http://xml.apache.org/xalan"
	
	exclude-result-prefixes="idpdisc md xalan"

	xmlns="urn:oasis:names:tc:SAML:2.0:metadata">

	<!--
		Force UTF-8 encoding for the output.
	-->
	<xsl:output omit-xml-declaration="no" method="xml" encoding="UTF-8"
		indent="yes" xalan:indent-amount="4"
	/>

	<xsl:strip-space elements="md:EntityDescriptor"/>
	
	<!--
		Top-level EntityDescriptor element.
	-->
	<xsl:template match="md:EntityDescriptor">
		<xsl:text>&#10;</xsl:text>
		<EntityDescriptor ID="uk000000_CHANGE_THIS"
			xsi:schemaLocation="urn:oasis:names:tc:SAML:2.0:metadata sstc-saml-schema-metadata-2.0.xsd
			urn:mace:shibboleth:metadata:1.0 shibboleth-metadata-1.0.xsd
			http://ukfederation.org.uk/2006/11/label uk-fed-label.xsd
			http://www.w3.org/2001/04/xmlenc# xenc-schema.xsd
			http://www.w3.org/2000/09/xmldsig# xmldsig-core-schema.xsd">
			
			<!--
				Copy across the @entityID attribute.  Other attributes from the input document
				are discarded.
			-->
			<xsl:attribute name="entityID"><xsl:value-of select="@entityID"/></xsl:attribute>

			<!--
				Entity comment.
			-->
			<!-- <xsl:text>&#10;</xsl:text> -->
			<xsl:text>&#10;</xsl:text>
			<xsl:comment>
				<xsl:text>&#10;</xsl:text>
				<xsl:text>        *** ENTITY COMMENT GOES HERE ***</xsl:text>
				<xsl:text>&#10;</xsl:text>
				<xsl:text>    </xsl:text>
			</xsl:comment>

			<!--
				Always have an Extensions element.  This may combine new material with any material
				present in an existing Extensions element.
			-->
			<Extensions>
				
				<!--
					Pull up scopes from role descriptor if they are not
					already present at the entity level.
				-->
				<xsl:if test="not(md:Extensions/shibmd:Scope)">
					<xsl:apply-templates select="md:IDPSSODescriptor/md:Extensions/shibmd:Scope"/>
				</xsl:if>
				
				<!--
					Always assumed to be owned by a member of the UK federation.
				-->
				<ukfedlabel:UKFederationMember/>

				<!--
					Dummy elements to include for IdPs only.
				-->
				<xsl:if test="md:IDPSSODescriptor">
					<xsl:comment> *** VERIFY OR REMOVE THE FOLLOWING ELEMENT *** </xsl:comment>
					<ukfedlabel:AccountableUsers/>
					<xsl:comment> *** VERIFY OR REMOVE THE FOLLOWING ELEMENT *** </xsl:comment>
					<wayf:HideFromWAYF xmlns:wayf="http://sdss.ac.uk/2006/06/WAYF"/>
				</xsl:if>

				<!--
					Dummy Software element.
				-->
				<ukfedlabel:Software name="Shibboleth"
					version="2" fullVersion="*** FILL IN OR REMOVE ***">
					<xsl:attribute name="date"><xsl:value-of select="mdxDates:date()"/></xsl:attribute>
				</ukfedlabel:Software>

				<!--
					Include any existing extensions at the top level.
				-->
				<xsl:apply-templates select="md:Extensions/*"/>

			</Extensions>
			
			<!--
				Express role descriptors in a fixed order.
			-->
			<xsl:apply-templates select="md:IDPSSODescriptor"/>
			<xsl:apply-templates select="md:AttributeAuthorityDescriptor"/>
			<xsl:apply-templates select="md:SPSSODescriptor"/>
			
			<!--
				Include an Organization if there isn't one there already.
			-->
			<xsl:choose>
				<xsl:when test="md:Organization">
					<xsl:apply-templates select="md:Organization"/>
				</xsl:when>
				<xsl:otherwise>
					<Organization>
						<OrganizationName xml:lang="en">*** FILL IN ***</OrganizationName>
						<OrganizationDisplayName xml:lang="en">*** FILL IN ***</OrganizationDisplayName>
						<OrganizationURL xml:lang="en">http://*** FILL IN ***/</OrganizationURL>
					</Organization>
				</xsl:otherwise>
			</xsl:choose>

			<!--
				Include a support contact if there isn't one.
			-->
			<xsl:choose>
				<xsl:when test="md:ContactPerson[@contactType='support']">
					<xsl:apply-templates select="md:ContactPerson[@contactType='support']"/>
				</xsl:when>
				<xsl:otherwise>
					<ContactPerson contactType="support">
						<GivenName>*** FILL IN ***</GivenName>
						<SurName>*** FILL IN ***</SurName>
						<EmailAddress>mailto:*** FILL IN ***</EmailAddress>
					</ContactPerson>
				</xsl:otherwise>
			</xsl:choose>

			<!--
				Include a technical contact if there isn't one.
			-->
			<xsl:choose>
				<xsl:when test="md:ContactPerson[@contactType='technical']">
					<xsl:apply-templates select="md:ContactPerson[@contactType='technical']"/>
				</xsl:when>
				<xsl:otherwise>
					<ContactPerson contactType="technical">
						<GivenName>*** FILL IN ***</GivenName>
						<SurName>*** FILL IN ***</SurName>
						<EmailAddress>mailto:*** FILL IN ***</EmailAddress>
					</ContactPerson>
				</xsl:otherwise>
			</xsl:choose>
			
			<!--
				Include an administrative contact if there isn't one.
			-->
			<xsl:choose>
				<xsl:when test="md:ContactPerson[@contactType='administrative']">
					<xsl:apply-templates select="md:ContactPerson[@contactType='administrative']"/>
				</xsl:when>
				<xsl:otherwise>
					<ContactPerson contactType="administrative">
						<GivenName>*** FILL IN ***</GivenName>
						<SurName>*** FILL IN ***</SurName>
						<EmailAddress>mailto:*** FILL IN ***</EmailAddress>
					</ContactPerson>
				</xsl:otherwise>
			</xsl:choose>
			
		</EntityDescriptor>
	</xsl:template>


	<!--
		Patch any @use-less KeyName descriptors in IdP roles
		for the benefit of Shib SPs pre-1.3.1.
	-->
	<xsl:template match="md:IDPSSODescriptor/md:KeyDescriptor[not(@use)] |
		md:AttributeAuthorityDescriptor/md:KeyDescriptor[not(@use)]">
		<xsl:copy>
			<xsl:attribute name="use">signing</xsl:attribute>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	
	<!--
		md:SPSSODescriptor
		
		Normalise namespace prefix.
	-->
	<xsl:template match="md:SPSSODescriptor">
		<SPSSODescriptor>
			<xsl:apply-templates select="node()|@*"/>
		</SPSSODescriptor>
	</xsl:template>
	
	
	<!--
		md:Extensions
		
		Normalise namespace prefix.
	-->
	<xsl:template match="md:Extensions">
		<Extensions>
			<xsl:apply-templates select="node()|@*"/>
		</Extensions>
	</xsl:template>
	
	
	<!--
		md:KeyDescriptor
		
		Normalise namespace prefix.
	-->
	<xsl:template match="md:KeyDescriptor">
		<KeyDescriptor>
			<xsl:apply-templates select="node()|@*"/>
		</KeyDescriptor>
	</xsl:template>
	
	
	<!--
		md:SingleLogoutService
		
		Normalise namespace prefix.
	-->
	<xsl:template match="md:SingleLogoutService">
		<SingleLogoutService>
			<xsl:apply-templates select="node()|@*"/>
		</SingleLogoutService>
	</xsl:template>
	
	
	
	<!--
		md:ManageNameIDService
		
		Normalise namespace prefix.
	-->
	<xsl:template match="md:ManageNameIDService">
		<ManageNameIDService>
			<xsl:apply-templates select="node()|@*"/>
		</ManageNameIDService>
	</xsl:template>
	
	
	<!--
		md:ArtifactResolutionService
		
		Normalise namespace prefix.
	-->
	<xsl:template match="md:ArtifactResolutionService">
		<ArtifactResolutionService>
			<xsl:apply-templates select="node()|@*"/>
		</ArtifactResolutionService>
	</xsl:template>
	
	
	<!--
		md:AssertionConsumerService
		
		Normalise namespace prefix.
	-->
	<xsl:template match="md:AssertionConsumerService">
		<AssertionConsumerService>
			<xsl:apply-templates select="node()|@*"/>
		</AssertionConsumerService>
	</xsl:template>
	
	
	<!--
		ds:KeyInfo
		
		Normalise namespace prefix.
	-->
	<xsl:template match="ds:KeyInfo">
		<ds:KeyInfo>
			<xsl:apply-templates select="node()|@*"/>
		</ds:KeyInfo>
	</xsl:template>
	
	
	<!--
		ds:KeyName
		
		Normalise namespace prefix.
	-->
	<xsl:template match="ds:KeyName">
		<ds:KeyName>
			<xsl:apply-templates select="node()|@*"/>
		</ds:KeyName>
	</xsl:template>
	
	
	<!--
		ds:X509Data
		
		Normalise namespace prefix.
	-->
	<xsl:template match="ds:X509Data">
		<ds:X509Data>
			<xsl:apply-templates select="node()|@*"/>
		</ds:X509Data>
	</xsl:template>
	
	
	<!--
		Normalise whitespace in X509Certificate elements.
	-->
	<xsl:template match="ds:X509Certificate">
		<xsl:element name="ds:X509Certificate">
			<xsl:text>&#10;</xsl:text>
			<xsl:value-of select="mdxTextUtils:wrapBase64(.)"/>
			<xsl:text>&#10;</xsl:text>
		</xsl:element>
	</xsl:template>
	
	
	<!--
		Discard ds:X509SubjectName
	-->
	<xsl:template match="ds:X509SubjectName">
		<!-- do nothing -->
	</xsl:template>
	
	
	<!--
		idpdisc:DiscoveryResponse
		
		Normalise namespace prefix, add missing Binding attribute.
	-->
	<xsl:template match="idpdisc:DiscoveryResponse">
		<DiscoveryResponse xmlns="urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol">
			<xsl:if test="not(@Binding)">
				<xsl:attribute name="Binding">urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="node()|@*"/>
		</DiscoveryResponse>
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
