# mds2hdcat · NFDI4Health-MDS → Health DCAT-AP

Convert a single **NFDI4Health [Local Data Hub](https://www.nfdi4health.de/en/service/local-data-hub.html) metadata record ([MDS JSON](https://simplifier.net/guide/nfdi4health---metadata-schema---implementationguide))** into valid  
**[Health DCAT-AP](https://healthdcat-ap.github.io/) 0.1.1 (Open-Data profile) JSON-LD** ready for [European Health Data Space](https://www.european-health-data-space.com/) (EHDS) catalogues.

---

## Requirements
* **Bash ≥ 3.2** (GNU/Linux)
* **jq ≥ 1.6** (JSON processor)
* *(optional)* **[Apache Jena `shacl`](https://jena.apache.org/documentation/shacl/)** for validation

## Usage
```bash
mds2hdcat.sh \
    --data   [MDS JSON data file] \
    --config [JSON config file] \
  > out.jsonld
```

## Quick start

```bash
# 1 - create institution settings
cp config_sample.json config.json      # edit the values

# 2 - fetch an MDS record from a Local Data Hub running on your machine
# or use the supplied test dataset
curl -H 'Accept: application/json' \
     http://localhost:3000/projects/1 > study.json

# 3 - convert
./mds2hdcat.sh \
    --data   mds-test-data/daytime-experiences-and-dreams-study.json \
    --config config.json \
  > study-hdcat.jsonld

# 4 - validate (optional)
shacl validate \
     --data   study-hdcat.jsonld \
     --shapes shapes/HealthDCAT-AP_opendata-shapes-v0.1.1.ttl
```

# JSON-LD result structure
The output of the transformation is **JSON-LD**, a serialization format of RDF, specifically designed to comply with the **Health DCAT-AP (Open Data profile)** specification.

We've chosen the following JSON-LD serialization structure:

- A top-level `@context`, mapping keys to IRIs.
- A `@graph` array containing separate nodes, each corresponding to one of the RDF Classes required by the Health DCAT-AP shapes:
  - **Dataset** (`dcat:Dataset`) – Core dataset metadata
  - **Publisher** (`foaf:Organization`) – Organization responsible for publishing the dataset
  - **Health Data Access Body (HDAB)** (`healthdcatap:HealthDataAccessBody`) – Entity managing data access permissions
  - **Distribution** (`dcat:Distribution`) – Technical and legal metadata for dataset access and distribution
  - **Contact Point** (`foaf:Agent`) – Entity for general user inquiries about dataset access and use

This serialization approach follows best practices from official EU [DCAT-AP examples](https://semiceu.github.io/DCAT-AP/releases/3.0.0/?utm_source=chatgpt.com#example-dataset-series), which similarly use structured JSON-LD documents containing `@context` and `@graph` nodes.

## License
- **Code:** This software is licensed under the MIT license. See [LICENSE](LICENSE) file for details.
- **External data:** The data files located in `mds-test-data/` are provided for demonstration purposes only and are **not covered** by the project's MIT license. Its usage rights remain subject to the original terms set by the data provider.
