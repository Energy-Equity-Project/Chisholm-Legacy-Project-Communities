
# Libraries
import os
import requests
import pandas as pd
from zipfile import ZipFile

# outputs directory
data_outdir = "data/acs_data"
gis_outdir = "data/GIS_Layers"
gis_compressed_dir = os.path.join(gis_outdir, "compressed")
gis_uncompressed_dir = os.path.join(gis_outdir, "uncompressed")

# Create output directories if needed
if not (os.path.exists(data_outdir)):
   os.mkdir(data_outdir)

if not (os.path.exists(gis_outdir)):
   os.mkdir(gis_outdir)

if not (os.path.exists(gis_compressed_dir)):
   os.mkdir(gis_compressed_dir)

if not (os.path.exists(gis_uncompressed_dir)):
   os.mkdir(gis_uncompressed_dir)

# Reading in US Census API Key
f = open("us_census_api_key.txt", "r")
ACS_API_KEY = f.read()
f.close()

# Define states in each TCLP region
tclp_regions = {
   # Region 5: California, Nevada, Utah, Arizona, Colorado
   5: ["06", "32", "49", "04", "08"],
   # Region 6: Washington, Oregon, Idaho, Montana, Wyoming
   6: ["53", "41", "16", "30", "56"],
   # Region 7: North Dakota, South Dakota, Nebraska, Kansas, Minnesota, Iowa
   7: ["38", "46", "31", "20", "27", "19"]
}

# ACS API endpoint
ACS_2022_URL = "https://api.census.gov/data/2022/acs/acs5"

# Variables we want to focus on
variable_groups = [
   "B19001", # Total number of Black or African American Alone Households by income level
   "B19001B", # Total number of households by income level
   "B02001" # Total population by Race
]

# Get data from US Census ACS 5-year survey 2022
for var_group in variable_groups:
   for region, states in tclp_regions.items():
      for state in states:
         # Get get group data for B19001B Number of Black or African American Alone Households across income levels
         resp = requests.get(f"{ACS_2022_URL}?get=NAME,group({var_group})&for=tract:*&in=state:{state}&key={ACS_API_KEY}")
         print(f"ACS Variable: {var_group}, TCLP Region: {region} State: {state}, Response {resp.status_code}")

         # Retrieve data from API response
         data = resp.json()
         # Transform data into a dataframe
         df = pd.DataFrame(data)
         # Turn first row of data into the header
         df.columns = df.iloc[0]
         df = df[1:]
         # Add TCLP region
         df["tclp_region"] = region
         # Write data out as CSV
         df.to_csv(os.path.join(data_outdir, f"{state}_{var_group}.csv"), index = False, header=True)

# Downloading all Census tract maps for states of interest
for region, states in tclp_regions.items():
   for state in states:
      # Downloading compressed data of GIS layers
      resp = requests.get(f"https://www2.census.gov/geo/tiger/TIGER2022/TRACT/tl_2022_{state}_tract.zip")
      print(f"GIS compressed data - TCLP Region {region}, State: {state}, Response code: {resp.status_code}")
      data = resp.content
      gis_zipfile = f"tl_2022_{state}_tract.zip"
      f = open(os.path.join(gis_compressed_dir, gis_zipfile), "wb")
      f.write(data)
      f.close()

      # uncompressing zipfiles of GIS layers
      print(f"Uncompressing {gis_zipfile}")
      zipped_data = ZipFile(os.path.join(gis_compressed_dir, gis_zipfile), "r")

      # Create output directory if it does not exist
      curr_uncompressed_dir = os.path.join(gis_uncompressed_dir, gis_zipfile[:-4])
      if not (os.path.exists(curr_uncompressed_dir)):
         os.mkdir(curr_uncompressed_dir)
      
      # Uncompress contents of zipfile into correct output directory
      zipped_data.extractall(curr_uncompressed_dir)
      zipped_data.close()


print("Done!")
