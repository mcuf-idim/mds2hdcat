################################################################################
# Inputs
################################################################################
def cfg : $cfg[0];
def mds : $mds[0];

################################################################################
# Aliases into MDS
################################################################################
def m  : mds.data.attributes.extended_attributes.attribute_map;
def id : m.Resource_identifier_Project;

# Note: We intentionally don't extract contact from MDS contributors
# as they represent scientific creators, not administrative contacts
def title : m.Resource_titles_Project[0].Resource_titles_text_Project;
def desc  : m.Resource_descriptions_Project[0].Resource_descriptions_text_Project;
def lang2 : (m.Resource_languages_Project[0] // "en") | ascii_downcase[0:2];
def langIRI :
    (if      lang2=="de" then "DEU"
     elif    lang2=="fr" then "FRA"
     else                 "ENG" end)
  | "http://publications.europa.eu/resource/authority/language/" + .;
def page : m.Resource_webpage_Project | if . == "" or . == null then null else . end;
def keywords : [m.Resource_keywords_Project[]?.Resource_keywords_label_Project] | map(select(. != null and . != ""));
def issued   : mds.data.meta.created;
def modified : mds.data.meta.modified;

################################################################################
# IDs derived from config
################################################################################
def iriStem : cfg.iriStem;
def dataset_id : (iriStem + "dataset/" + id);
def pub_id     : (iriStem + "publisher");
def hdab_id    : cfg.hdab["@id"];
def dist_id    : dataset_id + "/dist1";
def cp_bnode   : "_:contact";

# Extract primary creator from MDS contributors (first personal contributor)
def creator_id : 
  [m.Resource_contributors_Project[]? | 
   select(.Resource_contributors_nameType_Project == "Personal") | 
   .Resource_contributors_personal_Project][0] as $person |
  if $person and
     $person.Resource_contributors_personal_familyName_Project and 
     ($person.Resource_contributors_personal_familyName_Project != "") then
    "_:creator"
  else
    null
  end;

def creator_node :
  [m.Resource_contributors_Project[]? | 
   select(.Resource_contributors_nameType_Project == "Personal") | 
   .Resource_contributors_personal_Project][0] as $person |
  if $person and
     $person.Resource_contributors_personal_familyName_Project and 
     ($person.Resource_contributors_personal_familyName_Project != "") then
    {
      "@id": "_:creator",
      "type": "foaf:Person",
      "name": (($person.Resource_contributors_personal_givenName_Project // "") + " " + 
               ($person.Resource_contributors_personal_familyName_Project // "")) | gsub("^\\s+|\\s+$"; "")
    }
  else
    null
  end;

################################################################################
# Helpers
################################################################################
# healthCategory from config (EHDS Art.51 data source type, not MDS study design).
# The controlled vocabulary is mandated by Health DCAT-AP Release 6, §10.3.1:
#   http://13.81.34.152:1101/resource/authority/healthcategories/
# NOTE: The vocabulary server currently uses a development IP address.
# This IRI is expected to move to a permanent domain once the EU
# Publications Office publishes the vocabulary as a Named Authority List.
# See: https://healthdataeu.pages.code.europa.eu/healthdcat-ap/releases/release-6/
def health_cat :
  cfg.defaults.healthCategory as $hc |
  if $hc and $hc != "" then { "@id": $hc } else null end;

def licenceIRI : cfg.defaults.license;

# Access rights: extract from MDS dataSharingPlan, fall back to config default
# EU vocabulary: PUBLIC, RESTRICTED, NON_PUBLIC
# Only exact matches are trusted; anything else falls back to config default
def accessRightsIRI :
  (m.Design_Project.Design_dataSharingPlan_Project.Design_dataSharingPlan_generally_Project // "") as $plan |
  (cfg.defaults.accessRights // "NON_PUBLIC") as $default |
  (if   $plan == "PUBLIC" then "PUBLIC"
   elif $plan == "RESTRICTED" then "RESTRICTED"
   elif $plan == "NON_PUBLIC" then "NON_PUBLIC"
   else $default
   end) |
  "http://publications.europa.eu/resource/authority/access-right/" + .;

def nnint($n): { "@value": ($n|tostring), "@type":"xsd:nonNegativeInteger" };

# Extract age ranges from MDS eligibility criteria
def minAge : 
  (m.Design_Project.Design_eligibilityCriteria_Project.Design_eligibilityCriteria_ageMin_Project.Design_eligibilityCriteria_ageMin_number_Project // null) |
  if . and (. != "") and (. != null) then nnint(.) else null end;

def maxAge :
  (m.Design_Project.Design_eligibilityCriteria_Project.Design_eligibilityCriteria_ageMax_Project.Design_eligibilityCriteria_ageMax_number_Project // null) |
  if . and (. != "") and (. != null) then nnint(.) else null end;

################################################################################
# JSON-LD output
################################################################################
{
  "@context":{
    "dcat":"http://www.w3.org/ns/dcat#",
    "dct":"http://purl.org/dc/terms/",
    "foaf":"http://xmlns.com/foaf/0.1/",
    "healthdcatap":"http://healthdataportal.eu/ns/health#",
    "dcatap":"http://data.europa.eu/r5r/",
    "xsd":"http://www.w3.org/2001/XMLSchema#",

    "identifier":"dct:identifier",
    "title":"dct:title",
    "description":"dct:description",
    "landingPage":{"@id":"dcat:landingPage","@type":"@id"},

    "creator":"dct:creator",
    "publisher":{"@id":"dct:publisher","@type":"@id"},
    "hdab":{"@id":"healthdcatap:hdab","@type":"@id"},

    "issued":{"@id":"dct:issued","@type":"xsd:dateTime"},
    "modified":{"@id":"dct:modified","@type":"xsd:dateTime"},

    "license":{"@id":"dct:license","@type":"@id"},
    "accessRights":{"@id":"dct:accessRights","@type":"@id"},
    "applicableLegislation":{"@id":"dcatap:applicableLegislation","@type":"@id"},

    "distribution":{"@id":"dcat:distribution","@type":"@id"},
    "theme":{"@id":"dcat:theme","@type":"@id"},
    "keyword":"dcat:keyword",
    "contactPoint":{"@id":"dcat:contactPoint","@type":"@id"},

    "healthCategory":{"@id":"healthdcatap:healthCategory","@type":"@id"},
    "personalData":"healthdcatap:personalData",

    "numberOfRecords":"healthdcatap:numberOfRecords",
    "numberOfUniqueIndividuals":"healthdcatap:numberOfUniqueIndividuals",
    "minTypicalAge":"healthdcatap:minTypicalAge",
    "maxTypicalAge":"healthdcatap:maxTypicalAge",

    "language":{"@id":"dct:language","@type":"@id"},
    "spatial":{"@id":"dct:spatial","@type":"@id"},

    "name":"foaf:name",
    "mbox":{"@id":"foaf:mbox","@type":"@id"},
    "homepage":{"@id":"foaf:homepage","@type":"@id"},

    "publisherType":{"@id":"healthdcatap:publisherType","@type":"@id"},
    "publisherNote":"healthdcatap:publisherNote",
    "trustedDataHolder":{"@id":"healthdcatap:trustedDataHolder","@type":"xsd:boolean"},

    "format":{"@id":"dct:format","@type":"@id"},
    "rights":{"@id":"dct:rights","@type":"@id"},
    "byteSize":{"@id":"dcat:byteSize","@type":"xsd:nonNegativeInteger"},
    "mediaType":{"@id":"dcat:mediaType","@type":"@id"},
    "accessURL":{"@id":"dcat:accessURL","@type":"@id"},

    "type":"@type"
  },

  "@graph": ([
    ({
      "@id": dataset_id,
      "type":"dcat:Dataset",
      "identifier": id,
      "title": { "@value": title, "@language": lang2 },
      "description": { "@value": desc, "@language": lang2 },
      "publisher": { "@id": pub_id },
      "hdab": { "@id": hdab_id },
      "issued": issued,
      "modified": modified,
      "license": licenceIRI,
      "accessRights": { "@id": accessRightsIRI },
      "applicableLegislation": { "@id":"http://data.europa.eu/eli/reg/2016/679/oj" },
      "distribution": { "@id": dist_id },
      "theme": { "@id": cfg.defaults.theme },
      "contactPoint": { "@id": cp_bnode },
      "personalData": true,
      "language": { "@id": langIRI },
      "spatial": { "@id":"http://publications.europa.eu/resource/authority/country/DEU" }
    } 
    + (if creator_id then {"creator": { "@id": creator_id }} else {} end)
    + (if keywords | length > 0 then {"keyword": keywords} else {} end)
    + (if page then {"landingPage": {"@id": page}} else {} end)
    + (if health_cat then {"healthCategory": health_cat} else {} end)
    + (if minAge then {"minTypicalAge": minAge} else {} end)
    + (if maxAge then {"maxTypicalAge": maxAge} else {} end)),
    {
      "@id": pub_id,
      "type":"foaf:Organization",
      "name": cfg.publisher.name,
      "homepage": { "@id": cfg.publisher.homepage },
      "publisherType": { "@id": cfg.publisher.type },
      "publisherNote": cfg.publisher.note,
      "trustedDataHolder": cfg.publisher.trustedDataHolder
    },
    {
      "@id": hdab_id,
      "type":"healthdcatap:HealthDataAccessBody",
      "name": cfg.hdab.name,
      "homepage": { "@id": cfg.hdab.homepage },
      "mbox": { "@id": cfg.hdab.mbox }
    },
    {
      "@id": dist_id,
      "type":"dcat:Distribution",
      "accessURL": { "@id": (page // dataset_id) },
      "mediaType": { "@id":"https://www.iana.org/assignments/media-types/text/html" },
      "format": { "@id":"https://www.iana.org/assignments/media-types/text/html" },
      "byteSize": nnint(cfg.defaults.byteSize),
      "rights": { "@id": licenceIRI },
      "applicableLegislation": { "@id":"http://data.europa.eu/eli/reg/2016/679/oj" }
    },
    {
      "@id": cp_bnode,
      "type":"foaf:Agent",
      "name": cfg.contact.name,
      "mbox": { "@id": cfg.contact.mbox },
      "homepage": { "@id": cfg.contact.homepage }
    },
    creator_node
  ] | map(select(. != null)))
}