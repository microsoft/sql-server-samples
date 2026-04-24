//==============================================================================
//
//    © Microsoft corp. All rights reserved.
//    This code is licensed under the Microsoft Public License.
//    THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
//    ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
//    IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
//    PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
//
//==============================================================================
using System;
using System.IO;
using System.Xml;
using System.Xml.Serialization;
using Security.MDSTestService; // For the created service reference.

namespace Security
{
    class Program
    {
        // MDS service client proxy object.
        private static ServiceClient clientProxy;
        // MDS URL.
        private static string mdsURL = @"http://{0}/{1}/Service/Service.svc";

        static void Main(string[] args)
        {
            try
            {
                if (args.Length < 4 || args.Length > 5)
                {
                    Console.WriteLine("Usage: SecuritySample mode mds_host_name mds_application_name file_name [ExcludeMetadata]");
                    Console.WriteLine(string.Empty);
                    Console.WriteLine("mode: Indicates whether the code exports or imports the security information.");
                    Console.WriteLine("    \"mode\" value is Export or Import.");
                    Console.WriteLine(string.Empty);
                    Console.WriteLine("mds_host_name: The host name of the MDS web site.");
                    Console.WriteLine(string.Empty);
                    Console.WriteLine("mds_application_name: The MDS Application name.");
                    Console.WriteLine(string.Empty);
                    Console.WriteLine("file_name: The name of the file that stores the security information for users and groups.");
                    Console.WriteLine(string.Empty);
                    Console.WriteLine("ExcludeMetadata (optional): Indicates if Metadata Model Permissions are excluded or not.");
                    Console.WriteLine("    When \"ExcludeMetadata\" is specified Metadata Model Permissions are excluded.");
                    Console.WriteLine(string.Empty);
                    return;
                }

                string mode = args[0];
                string hostName = args[1];
                string applicationName = args[2];
                string fileName = args[3];

                mdsURL = string.Format(mdsURL, hostName, applicationName);

                // Creates a service proxy.
                clientProxy = GetClientProxy(mdsURL);

                // Check if Exclude Metadata Model Permissions flag is set.
                // When Metadata Model's GUID in the target MDS application is different from the one in the source MDS application, the import of the security information fails.
                // To avoid this issue the user can exclude Metadata Model Permissions.
                // The user can use Model Deployment to create other models with the same GUIDs as the source MDS application.
                bool excludeMetadataPermission = false;

                if (args.Length == 5)
                {
                    if (string.Equals(args[4], "ExcludeMetadata", StringComparison.OrdinalIgnoreCase))
                    {
                        excludeMetadataPermission = true;
                    }
                }

                if (string.Equals(mode, "Export", StringComparison.OrdinalIgnoreCase))
                {
                    // Gets the security information and exports it into the files.
                    ExportSecurityInformation(excludeMetadataPermission, fileName);
                }
                else if (string.Equals(mode, "Import", StringComparison.OrdinalIgnoreCase))
                {
                    // Imports the security information from the files.
                    ImportSecurityInformation(excludeMetadataPermission, fileName);
                }

            }
            catch (Exception ex)
            {
                Console.WriteLine("Error {0}", ex);
            }

        }

        // Creates MDS service client proxy.
        private static ServiceClient GetClientProxy(string targetURL)
        {
            // Creates an endpoint address using the URL.
            System.ServiceModel.EndpointAddress endptAddress = new System.ServiceModel.EndpointAddress(targetURL);

            // Creates and configures the WS Http binding.
            System.ServiceModel.WSHttpBinding wsBinding = new System.ServiceModel.WSHttpBinding();

            // Creates and returns the client proxy.
            return new ServiceClient(wsBinding, endptAddress);
        }

        // Handles operation errors.
        private static void HandleOperationErrors(MDSTestService.OperationResult result)
        {
            string errorMessage = string.Empty;

            if (result.Errors.Count > 0)
            {
                foreach (MDSTestService.Error anError in result.Errors)
                {
                    errorMessage += "Operation Error: " + anError.Code + ":" + anError.Description + "\n";
                }
                // Show the error messages.
                Console.WriteLine(errorMessage);
            }
        }

        // Gets security information and exports it into the files.
        // excludeMetadataPermission indicates if model privileges for Metadata are exluded.
        private static void ExportSecurityInformation(bool excludeMetadataPermission, string fileName)
        {
            // Gets security information.
            SecurityPrincipalsGetRequest principalGetRequest = new SecurityPrincipalsGetRequest();
            principalGetRequest.Criteria = new SecurityPrincipalsCriteria();
            principalGetRequest.Criteria.All = true;
            principalGetRequest.Criteria.Type = PrincipalType.UserAccount;
            principalGetRequest.Criteria.ResultType = ResultType.Details;
            principalGetRequest.Criteria.SecurityResolutionType = SecurityResolutionType.Users;
            principalGetRequest.Criteria.ModelPrivilege = ResultType.Details;
            principalGetRequest.Criteria.FunctionPrivilege = ResultType.Details;
            principalGetRequest.Criteria.HierarchyMemberPrivilege = ResultType.Details;

            // Gets the security principals for all the users.
            SecurityPrincipalsGetResponse principalGetResponse = clientProxy.SecurityPrincipalsGet(principalGetRequest);
            HandleOperationErrors(principalGetResponse.OperationResult);

            System.Collections.ObjectModel.Collection<User> users = principalGetResponse.Principals.Users;

            // Exclude model privileges for Metadata when excludeMetadataPermission is true.
            if (excludeMetadataPermission)
            {
                foreach (User anUser in users)
                {
                    System.Collections.ObjectModel.Collection<ModelPrivilege> tempModelPrivileges = new System.Collections.ObjectModel.Collection<ModelPrivilege>{};

                    // Exclude model privileges for Metadata (internal id = 1).
                    foreach (ModelPrivilege aPrivilege in anUser.SecurityPrivilege.ModelPrivileges)
                    {
                        if (aPrivilege.ModelId.InternalId != 1)
                        {
                            tempModelPrivileges.Add(aPrivilege);
                        }
                    }

                    anUser.SecurityPrivilege.ModelPrivileges = tempModelPrivileges;
                }
            }

            principalGetRequest.Criteria.Type = PrincipalType.Group;
            principalGetRequest.Criteria.SecurityResolutionType = SecurityResolutionType.UserAndGroup;

            // Gets the security principals for all the groups.
            SecurityPrincipalsGetResponse principalGetGroupResponse = clientProxy.SecurityPrincipalsGet(principalGetRequest);
            HandleOperationErrors(principalGetGroupResponse.OperationResult);

            System.Collections.ObjectModel.Collection<Group> groups = principalGetGroupResponse.Principals.Groups;

            // Exclude model privileges for Metadata when excludeMetadataPermission is true.
            if (excludeMetadataPermission)
            {
                foreach (Group aGroup in groups)
                {
                    System.Collections.ObjectModel.Collection<ModelPrivilege> tempModelPrivileges = new System.Collections.ObjectModel.Collection<ModelPrivilege> { };

                    // Exclude model privileges for Metadata (internal id = 1).
                    foreach (ModelPrivilege aPrivilege in aGroup.SecurityPrivilege.ModelPrivileges)
                    {
                        if (aPrivilege.ModelId.InternalId != 1)
                        {
                            tempModelPrivileges.Add(aPrivilege);
                        }
                    }

                    aGroup.SecurityPrivilege.ModelPrivileges = tempModelPrivileges;
                }
            }

            // Set users and groups objects to securityInformation.
            SecurityInformation securityInformation = new SecurityInformation();
            securityInformation.Users = users;
            securityInformation.Groups = groups;

            // Serialization.
            XmlSerializer serializer = new XmlSerializer(typeof(SecurityInformation));

            using (FileStream fs = new FileStream(fileName, FileMode.Create, FileAccess.Write))
            {
                XmlDictionaryWriter xmlWriter = XmlDictionaryWriter.CreateBinaryWriter(fs);

                // Serializes the security information.
                serializer.Serialize(xmlWriter, securityInformation);
                fs.Flush();
            }

        }

        // Imports the security information from the files.
        // excludeMetadataPermission indicates if model privileges for Metadata are exluded.
        private static void ImportSecurityInformation(bool excludeMetadataPermission, string fileName)
        {
            // Deserialization.
            System.Collections.ObjectModel.Collection<User> users;
            System.Collections.ObjectModel.Collection<Group> groups;
            SecurityInformation securityInformation = new SecurityInformation();

            XmlSerializer serializer = new XmlSerializer(typeof(SecurityInformation));

            using (FileStream fs = new FileStream(fileName, FileMode.Open, FileAccess.Read))
            {
                XmlDictionaryReader xmlReader = XmlDictionaryReader.CreateBinaryReader(fs, XmlDictionaryReaderQuotas.Max);

                // Derializes the security information.
                securityInformation = (SecurityInformation)serializer.Deserialize(xmlReader);
            }

            // Gets users and groups objects from securityInformation.
            users = securityInformation.Users;
            groups = securityInformation.Groups;

            // Exclude model privileges for Metadata when excludeMetadataPermission is true.
            if (excludeMetadataPermission)
            {
                foreach (User anUser in users)
                {
                    System.Collections.ObjectModel.Collection<ModelPrivilege> tempModelPrivileges = new System.Collections.ObjectModel.Collection<ModelPrivilege> { };

                    // Exclude model privileges for Metadata (internal id = 1).
                    foreach (ModelPrivilege aPrivilege in anUser.SecurityPrivilege.ModelPrivileges)
                    {
                        if (aPrivilege.ModelId.InternalId != 1)
                        {
                            tempModelPrivileges.Add(aPrivilege);
                        }
                    }

                    anUser.SecurityPrivilege.ModelPrivileges = tempModelPrivileges;
                }
            }

            // Exclude model privileges for Metadata when excludeMetadataPermission is true.
            if (excludeMetadataPermission)
            {
                foreach (Group aGroup in groups)
                {
                    System.Collections.ObjectModel.Collection<ModelPrivilege> tempModelPrivileges = new System.Collections.ObjectModel.Collection<ModelPrivilege> { };

                    // Exclude model privileges for Metadata (internal id = 1).
                    foreach (ModelPrivilege aPrivilege in aGroup.SecurityPrivilege.ModelPrivileges)
                    {
                        if (aPrivilege.ModelId.InternalId != 1)
                        {
                            tempModelPrivileges.Add(aPrivilege);
                        }
                    }

                    aGroup.SecurityPrivilege.ModelPrivileges = tempModelPrivileges;
                }
            }

            // Clones security principals for groups and users.
            SecurityPrincipalsRequest principalRequest = new SecurityPrincipalsRequest();
            principalRequest.Principals = new SecurityPrincipals();
            principalRequest.Principals.Groups = new System.Collections.ObjectModel.Collection<Group> { };
            principalRequest.Principals.Users = new System.Collections.ObjectModel.Collection<User> { };

            // Sets group objects.
            foreach (Group aGroup in groups)
            {
                principalRequest.Principals.Groups.Add(aGroup);
            }

            // Creates groups and their security principals.
            // Create groups before users since some of the users may belong to one of the groups and reference the group object.
            // Note that the security information assumes that GUIDs for objects such as Models are the same.
            MessageResponse response = clientProxy.SecurityPrincipalsClone(principalRequest);
            HandleOperationErrors(response.OperationResult);

            principalRequest.Principals.Groups = new System.Collections.ObjectModel.Collection<Group> { };
            principalRequest.Principals.Users = new System.Collections.ObjectModel.Collection<User> { };

            // Sets user objects.
            foreach (User aUser in users)
            {
                principalRequest.Principals.Users.Add(aUser);
            }

            // Creates users and their security principals.
            response = clientProxy.SecurityPrincipalsClone(principalRequest);
            HandleOperationErrors(response.OperationResult);
        }
    }
}
