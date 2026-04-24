CREATE PROCEDURE [DataLoadSimulation].[GetBuyingGroupDomain]
  @BuyingGroup AS NVARCHAR(50)
, @WebDomain   AS NVARCHAR(256) OUTPUT
, @EmailDomain AS NVARCHAR(256) OUTPUT
AS
BEGIN
/*
Notes:
  Unfortunately the URLs for the buying groups aren't found
  elsewhere, so we have to create a proc with them hard
  coded and use this proc to look them up

Usage:
  DECLARE @myDomain AS NVARCHAR(256)
  EXEC [DataLoadSimulation].[GetBuyingGroupDomain]
      @BuyingGroup = 'Woodgrove Bank'
    , @WebDomain   = @myWebDomain OUTPUT
    , @EmailDomain = @myEmailDomain OUTPUT
  SELECT @myURL

*/

  DECLARE @urls AS TABLE ( BuyingGroupName NVARCHAR(50)
                         , WebDomain       NVARCHAR(256)
                         , EmailDomain     NVARCHAR(256)
)

  INSERT INTO @urls (BuyingGroupName, WebDomain, EmailDomain)
  VALUES
      (N'Datum Corporation',                          N'http://www.adatum.com/',                               N'adatum.com')
    , (N'Adventure Works Cycles',                     N'http://www.adventure-works.com/',                      N'adventure-works.com')
    , (N'Alpine Ski House',                           N'http://www.alpineskihouse.com/',                       N'alpineskihouse.com')
    , (N'Bellows College',                            N'http://www.bellowscollege.com',                        N'bellowscollege.com')
    , (N'Best For You Organics Company',              N'http://www.bestforyouorganics.com',                    N'bestforyouorganics.com')
    , (N'Blue Younder Airlines',                      N'http://www.blueyonderairlines.com/',                   N'blueyonderairlines.com')
    , (N'City Power & Light',                         N'http://www.cpandl.com/',                               N'cpandl.com')
    , (N'Coho Vineyard',                              N'http://www.cohovineyard.com/',                         N'cohovineyard.com')
    , (N'Coho Winery',                                N'http://www.cohowinery.com/',                           N'cohowinery.com')
    , (N'Coho Vineyard & Winery',                     N'http://www.cohovineyardandwinery.com/',                N'cohovineyardandwinery.com')
    , (N'Contoso, Ltd.',                              N'http://www.contoso.com/',                              N'contoso.com')
    , (N'Contoso Pharmaceuticals',                    N'http://www.contoso.com/',                              N'contoso.com')
    , (N'Contoso Suites',                             N'http://www.contososuites.com',                         N'contososuites.com')
    , (N'Consolidated Messenger',                     N'http://www.consolidatedmessenger.com/',                N'consolidatedmessenger.com')
    , (N'Fabrikam, Inc.',                             N'http://www.fabrikam.com/',                             N'fabrikam.com')
    , (N'Fabrikam Residences',                        N'http://fabrikamresidences.com',                        N'fabrikamresidences.com')
    , (N'First Up Consultants',                       N'http://firstupconsultants.com',                        N'firstupconsultants.com')
    , (N'Fourth Coffee',                              N'http://www.fourthcoffee.com/',                         N'fourthcoffee.com')
    , (N'Graphic Design Institute',                   N'http://www.graphicdesigninstitute.com/',               N'graphicdesigninstitute.com')
    , (N'Humongous Insurance',                        N'http://www.humongousinsurance.com/',                   N'humongousinsurance.com')
    , (N'Lamna Healthcare Company',                   N'http://www.lamnahealtcare.com',                        N'lamnahealtcare.com')
    , (N'Litware, Inc.',                              N'http://www.litwareinc.com/',                           N'litwareinc.com')
    , (N'Liberty''s Delightful Sinful Bakery & Cafe', N'http://www.libertysdelightfulsinfulbakeryandcafe.com', N'libertysdelightfulsinfulbakeryandcafe.com')
    , (N'Lucerne Publishing',                         N'http://www.lucernepublishing.com/',                    N'lucernepublishing.com')
    , (N'Margie''s Travel',                           N'http://www.margiestravel.com/',                        N'margiestravel.com')
    , (N'Munson''s Pickles and Preserves Farm',       N'http://www.munsonspicklesandpreservesfarm.com',        N'munsonspicklesandpreservesfarm.com')
    , (N'Nod Publishers',                             N'http://www.nodpublishers.com',                         N'nodpublishers.com')
    , (N'Northwind Electric Cars',                    N'http://www.northwindelectriccars.com',                 N'northwindelectriccars.com')
    , (N'Northwind Traders',                          N'http://www.northwindtraders.com/',                     N'northwindtraders.com')
    , (N'Proseware, Inc.',                            N'http://www.proseware.com/',                            N'proseware.com')
    , (N'Relecloud',                                  N'http://www.relecloud.com',                             N'relecloud.com')
    , (N'School of Fine Art',                         N'http://www.fineartschool.net',                         N'fineartschool.net')
    , (N'Southridge Video',                           N'http://www.southridgevideo.com/',                      N'southridgevideo.com')
    , (N'Tailspin Toys',                              N'http://www.tailspintoys.com/',                         N'tailspintoys.com')
    , (N'Trey Research',                              N'http://www.treyresearch.net/',                         N'treyresearch.net')
    , (N'The Phone Company',                          N'http://www.thephone-company.com/',                     N'thephone-company.com')
    , (N'VanArsdel, Ltd.',                            N'http://www.vanarsdelltd.com',                          N'vanarsdelltd.com')
    , (N'Wide World Importers',                       N'http://www.wideworldimporters.com/',                   N'wideworldimporters.com')
    , (N'Wingtip Toys',                               N'http://wingtiptoys.com/',                              N'wingtiptoys.com')
    , (N'Woodgrove Bank',                             N'http://www.woodgrovebank.com/',                        N'woodgrovebank.com')
    , (N'Individual Buyer',                           N'N/A',                                                  N'N/A')

  SET @WebDomain = N'N/A'
  SET @EmailDomain = N'N/A'
  SELECT @WebDomain = WebDomain, @EmailDomain = EmailDomain
    FROM @urls
   WHERE BuyingGroupName = @BuyingGroup

END

