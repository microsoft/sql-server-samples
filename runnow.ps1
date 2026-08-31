.\manage-payg-transition\modify-arc-sql-license-type.ps1 `
-UsePcoreLicense 'No' `
-ReportOnly `
-TenantId '72f988bf-86f1-41af-91ab-2d7cd011db47' `
-NoSummary `
-LicenseType 'PAYG' `
-SubId 'a5082b19-8a6e-4bc5-8fdd-8ef39dfebc39' `
-ResourceGroup 'rajpoArcEUSUSP' `
-Force
.\manage-payg-transition\modify-azure-sql-license-type.ps1 `
-LicenseType 'LicenseIncluded' `
-ResourceGroup 'rajpoArcEUSUSP' `
-SubId 'a5082b19-8a6e-4bc5-8fdd-8ef39dfebc39' `
-TenantId '72f988bf-86f1-41af-91ab-2d7cd011db47' `
-NoSummary `
-ReportOnly
