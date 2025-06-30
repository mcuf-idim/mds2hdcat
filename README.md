# mds2hdcat · NFDI4Health-MDS → Health DCAT-AP

Convert a single **NFDI4Health metadata record ([MDS JSON](https://simplifier.net/guide/nfdi4health---metadata-schema---implementationguide))** into valid  
**[Health DCAT-AP](https://healthdcat-ap.github.io/) 0.1.1 (Open-Data profile) JSON-LD** ready for [European Health Data Space](https://www.european-health-data-space.com/) (EHDS) catalogues.

---

## Requirements
* **Bash ≥ 3.2** (Linux)
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

## License
- **Code:** This software is licensed under the MIT license. See [LICENSE](LICENSE) file for details.
- **External data:** The data files located in `mds-test-data/` are provided for demonstration purposes only and are **not covered** by the project's MIT license. Its usage rights remain subject to the original terms set by the data provider.
