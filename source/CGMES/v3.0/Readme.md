# Short Description of the Provided Application Profiles

The application profiles are provided to facilitate the implementation of the **CGMES profiles** and related constraints as defined in **IEC 61970-600-1:2021**, **IEC 61970-600-2:2021**, **IEC 61970-301**, and other related 61970-45x series of profiles. The application profiles are packaged in the following folders:

### RDFS2020
An improved export of the RDFS augmented version based on **IEC 61970-501:2006 (Ed1)**, used for exporting the RDFS for **CGMES v2.4** and **CGMES v3.0**. The only difference is the resolution of technical export issues and the instantiation of information from the abstract version class into the header of the RDFS. Note that "2020" refers to the augmented RDFS export version by **CimSyntaxGen**, not the year of generation.

### RDFSEd2Beta
This is a **beta version of RDFS** based on the draft **IEC 61970-501:Ed2**. These files provide insight into the future direction of RDFS. The RDFS includes vocabulary, and the constraints (cardinalities, datatypes, etc.) are expressed through **SHACL**.

### SHACL
This package contains all **SHACL shapes/constraints** applicable for **CGMES v3.0**. These constraints cover cardinalities and datatypes derived from the RDFS, as well as those defined in **IEC 61970-600-1:2021**, **IEC 61970-600-2:2021**, **IEC 61970-301**, and other 61970-45x profiles. The constraints are serialized in **TURTLE** and **RDF/XML** formats. However, as many constraints rely on the SHACL SPARQL method, which is not covered in **IEC 61970-501:Ed2**, the RDF/XML version should be used with caution.

### OCL
This package contains **OCL-based constraints** for **CGMES v3.0**, similar to how SHACL shapes cover it. The `RDFS Extracted` folder includes OCL constraints derived from the RDFS, while the `XLSX Extracted` folder contains constraints from the descriptions of classes and attributes and from **IEC 61970-600-1:2021**, **IEC 61970-600-2:2021**, and **IEC 61970-301**. This package was developed in November 2020, and there may be deviations from the published version of CGMES v3.0. This package will not be maintained.

## Disclaimer
The test configurations (models), documents, and application profiles are owned by **ENTSO-E** and are provided "as is". To the fullest extent permitted by law, ENTSO-E shall not be liable for any damages arising from their use. ENTSO-E neither warrants nor represents that the use of the profiles will not infringe the rights of third parties. Any use of the profiles must include a reference to ENTSO-E. **ENTSO-E's website** is the only official source for these profiles.
