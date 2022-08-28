*/
DATA CLEANING PROJECT
*/


--Standardizing Date Format, since right now it shows time Datetime, which is not necessary

SELECT SaleDate, CONVERT (Date, SaleDate)
FROM SQLcleaningproject.dbo.NashvilleHousing

UPDATE NashvilleHousing 
SET SaleDate = CONVERT (Date, SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);
--Job done!



--Populating the PropertyAddress column with data, since many has null values

SELECT PropertyAddress
FROM SQLcleaningproject.dbo.NashvilleHousing
WHERE PropertyAddress is null;

SELECT * 
FROM SQLcleaningproject.dbo.NashvilleHousing
ORDER BY ParcelID --As we can see when we browse trought the data with this query, the ParcelID is always unique for the address
--So we can use this to populate the missing addresses.

--To do this we need to join the table by itself on parcelid where the uniqueID on both are NOT equal to eachother
--Since these will be the ones with null values. The ISNULL statement works like: 
--First argument put the column to check if its NULL. Second argument says if it is null, what to populate it with.
--So here we say that it should populate the nulls in a.propertyaddress with the propertyaddress from b

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b. PropertyAddress,
ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM SQLcleaningproject.dbo.NashvilleHousing AS a
JOIN SQLcleaningproject.dbo.NashvilleHousing AS b
ON a.ParcelID = b.ParcelID
AND a.[uniqueID] != b. [UniqueID]
WHERE a.PropertyAddress is null

--We then use this query to update the table
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM SQLcleaningproject.dbo.NashvilleHousing AS a
JOIN SQLcleaningproject.dbo.NashvilleHousing AS b
ON a.ParcelID = b.ParcelID
AND a.[uniqueID] != b. [UniqueID]
where a.PropertyAddress is null;

--Job done!



--Breaking out Address into individual columns, since address, city and state is in the same column). Since Address and City is
--Separated by a , we use a char index inside a substring
SELECT PropertyAddress
FROM SQLcleaningproject.dbo.NashvilleHousing

--The first substring starts at the first value in propertyaddress and stops at the , -1. 
--The second one starts at the , +1 and goes for the length of PropertyAddress (meaning the , and onwards).
SELECT 
SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address, --This says: For PropertyAddress check from the first value untill the , specified in the CHARINDEX, we specify -1 to get rid of the comma
SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as Address 
FROM SQLcleaningproject.dbo.NashvilleHousing

--Now we add the new columns and then populate them by the substring
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing 
SET PropertySplitAddress = SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing 
SET PropertySplitCity = SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress));

--Job done!



--Doing another splitting of columns for OwnerAddress, but using parse name
SELECT OwnerAddress
FROM SQLcleaningproject.dbo.NashvilleHousing

--We use the REPLACE argument because PARSENAME only looks for . so we replace , with .
SELECT 
PARSENAME (REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME (REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME (REPLACE(OwnerAddress, ',', '.'), 1)
FROM SQLcleaningproject.dbo.NashvilleHousing

--Adding the columns and updating

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing 
SET OwnerSplitAddress = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing 
SET OwnerSplitCity = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing 
SET OwnerSplitState = PARSENAME (REPLACE(OwnerAddress, ',', '.'), 1);

-- Job done!


--Changing 'Y' and 'N' to 'Yes' and 'No' in SoldAsVacant to make it consistent
SELECT Distinct (SoldAsVacant), COUNT(SoldAsVacant)
FROM SQLcleaningproject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant);

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant -- This is used to indicate if it is already YES or NO then just keep as is
END
FROM SQLcleaningproject.dbo.NashvilleHousing;

--Using the query to update
UPDATE SQLcleaningproject.dbo.NashvilleHousing
SET SoldasVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant 
END;

--Job done!



--Removing Duplicates

WITH RowNumCTE AS(
SELECT *,
    ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference --The idea is if all of these are the same, then it has to be a duplicate
	ORDER BY ParcelID ) AS row_num
FROM SQLcleaningproject.dbo.NashvilleHousing
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1; -- Since row num above 1 identifies the duplicates

--Job done!




--Delete Unused Columns like the ones I seperated

SELECT * 
FROM SQLcleaningproject.dbo.NashvilleHousing;

ALTER TABLE SQLcleaningproject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict; 

ALTER TABLE SQLcleaningproject.dbo.NashvilleHousing
DROP COLUMN SaleDate; 

--Job done!