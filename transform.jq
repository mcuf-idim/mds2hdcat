
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
def title : m.Resource_titles_Project[0].Resource_titles_text_Project;
def desc  : m.Resource_descriptions_Project[0].Resource_descriptions_text_Project;
def lang2 : (m.Resource_languages_Project[0] // "en") | ascii_downcase[0:2];
def langIRI :
    (if      lang2=="de" then "DEU"
     elif    lang2=="fr" then "FRA"
     else                 "ENG" end)
  | "http://publications.europa.eu/resource/authority/language/" + .;
def page : m.Resource_webpage_Project;
def issued   : mds.data.meta.created;
def modified : mds.data.meta.modified;

################################################################################
# IDs derived from config
################################################################################
def iriStem : cfg.iriStem;
def dataset_id : (iriStem + "dataset/" + id);
def pub_id     : (iriStem + "publisher/" + (id|@uri));
def hdab_id    : (iriStem + "hdab/" + (id|@uri));
def dist_id    : dataset_id + "/dist1";
def cp_bnode   : "_:contact";

################################################################################
# Helpers
################################################################################
def health_cat :
  if (m.Design_Project.Design_primaryDesign_Project // "") | test("(?i)interventional")
  then { "@id":"https://semiceu.github.io/ehds/vocabulary/health-category/INTERVENTIONAL_STUDY" }
  else { "@id":"https://semiceu.github.io/ehds/vocabulary/health-category/OBSERVATIONAL_STUDY" } end;

def licenceIRI : cfg.defaults.license;

def nnint($n): { "@value": ($n|tostring), "@type":"xsd:nonNegativeInteger" };

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

  "@graph":[
    {
      "@id": dataset_id,
      "type":"dcat:Dataset",
      "identifier": id,
      "title": { "@value": title, "@language": lang2 },
      "description": { "@value": desc, "@language": lang2 },
      "landingPage": { "@id": page },
      "creator": { "@id": pub_id },
      "publisher": { "@id": pub_id },
      "hdab": { "@id": hdab_id },
      "issued": issued,
      "modified": modified,
      "license": licenceIRI,
      "accessRights": { "@id":"http://publications.europa.eu/resource/authority/access-right/PUBLIC" },
      "applicableLegislation": { "@id":"http://data.europa.eu/eli/reg/2016/679/oj" },
      "distribution": { "@id": dist_id },
      "theme": { "@id": cfg.defaults.theme },
      "keyword": [ "EEG","sleep","dream" ],
      "contactPoint": { "@id": cp_bnode },
      "healthCategory": health_cat,
      "personalData": true,
      "numberOfRecords": nnint(20),
      "numberOfUniqueIndividuals": nnint(20),
      "minTypicalAge": nnint(20),
      "maxTypicalAge": nnint(30),
      "language": { "@id": langIRI },
      "spatial": { "@id":"http://publications.europa.eu/resource/authority/country/DEU" }
    },
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
    }
  ]
}