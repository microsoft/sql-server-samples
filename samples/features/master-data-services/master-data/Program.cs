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
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Linq;
using System.ServiceModel;
using MasterData.MDSTestService; // For the created service reference.

namespace MasterData
{
    static class Program
    {
        // MDS service client proxy object.
        private static ServiceClient clientProxy;
        // Set the MDS URL (plus /Service/Service.svc) here.
        private static string mdsURL = @"http://localhost/MDS/Service/Service.svc";

        static void Main()
        {
            Identifier modelId = null;
            try
            {
                // Create a service proxy.
                clientProxy = GetClientProxy(mdsURL);

                string model = "TestModel" + Guid.NewGuid().ToString("N");
                string entity = "TestEntity";
                string explicitHierarchy = "TestEH";
                // "VERSION_1" is a default version name for a new model.
                string version = "VERSION_1";

                modelId = CreateModel(model, entity, explicitHierarchy);

                // Create an entity member (leaf member) with a specified name, code, and member type.
                string leafMemberCode = "Code" + Guid.NewGuid().ToString("N");
                string leafMemberName = "Name" + Guid.NewGuid().ToString("N");
                CreateEntityMember(model, version, entity, leafMemberName, leafMemberCode, MemberType.Leaf);

                // Get the entity member identifier with specified model name, version name, entity name, member type, and entity member code.
                GetEntityMemberByCode(model, version, entity, MemberType.Leaf, leafMemberCode);

                // Update an entity member (change name) with the member code.
                leafMemberName = "Name" + Guid.NewGuid().ToString("N");
                UpdateEntityMember(model, version, entity, leafMemberCode, MemberType.Leaf, leafMemberName);

                // Create a consolidated memeber with specified name, code, member type, and hierarchy name.
                // HierarchyName is used only when the member type is Consolidated.
                string consolidatedMemberCode = "Code" + Guid.NewGuid().ToString("N");
                string consolidatedMemberName = "Name" + Guid.NewGuid().ToString("N");
                CreateEntityMember(model, version, entity, consolidatedMemberName, consolidatedMemberCode,
                    MemberType.Consolidated, explicitHierarchy);

                // Get the entity member identifier with specified model name, version name, entity name, member type, and entity member name.
                GetEntityMemberByName(model, version, entity, MemberType.Consolidated, consolidatedMemberName);

                // Update an entity member relationship.
                // You need to specify the existing hierachy name, parent member code, and child member code.
                UpdateEntityMemberRelationship(model, version, entity, explicitHierarchy, consolidatedMemberCode,
                    leafMemberCode);

                // Delete the leaf member with the member code.
                DeleteEntityMember(model, version, entity, leafMemberCode, MemberType.Leaf);

                // Delete the consolidated member with the member code.
                DeleteEntityMember(model, version, entity, consolidatedMemberCode, MemberType.Consolidated);

                string updateLeafMemberCode = "Code" + Guid.NewGuid().ToString("N");
                string updateLeafMemberName = "Name" + Guid.NewGuid().ToString("N");
                CreateEntityMember(model, version, entity, updateLeafMemberName, updateLeafMemberCode, MemberType.Leaf, "");

                string deleteLeafMemberCode = "Code" + Guid.NewGuid().ToString("N");
                string deleteLeafMemberName = "Name" + Guid.NewGuid().ToString("N");
                CreateEntityMember(model, version, entity, deleteLeafMemberName, deleteLeafMemberCode, MemberType.Leaf, "");

                SetApprovalRequired(model, entity, true);
                Debug.Assert( GetApprovalRequired(model, entity));

                string changesetName = "Changeset" + Guid.NewGuid().ToString("N");
                var changesetId = ChangesetSave(model, version, entity, new Identifier { Name = changesetName },
                    ChangesetStatus.Open);

                string newLeafMemberCode = "Code" + Guid.NewGuid().ToString("N");
                string newLeafMemberName = "Name" + Guid.NewGuid().ToString("N");
                CreateEntityMember(model, version, entity, newLeafMemberName, newLeafMemberCode, MemberType.Leaf, null, changesetName);

                updateLeafMemberName = "Name" + Guid.NewGuid().ToString("N");
                UpdateEntityMember(model, version, entity, updateLeafMemberCode, MemberType.Leaf, updateLeafMemberName, changesetName);

                DeleteEntityMember(model, version, entity, deleteLeafMemberCode, MemberType.Leaf, changesetName);

                var members = GetEntityMembers(model, version, entity, MemberType.Leaf, changesetName);
                Debug.Assert(members.Count == 3);

                // Submit to approve
                ChangesetSave(model, version, entity, changesetId, ChangesetStatus.Pending);

                // Approve require a different admin
                // ChangesetSave(model, version, entity, changesetId, ChangesetStatus.Approved);

                // Recall
                ChangesetSave(model, version, entity, changesetId, ChangesetStatus.Open);

                // Delete
                ChangesetDelete(model, version, changesetName);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }
            finally
            {
                if (modelId != null)
                {
                    DeleteModel(modelId);
                }
            }
        }

        // Creates MDS service client proxy.
        private static ServiceClient GetClientProxy(string targetURL)
        {
            // Create an endpoint address using the URL.
            EndpointAddress endptAddress = new EndpointAddress(targetURL);

            // Create and configure the WS Http binding.
            WSHttpBinding wsBinding = new WSHttpBinding();

            // Create and return the client proxy.
            return new ServiceClient(wsBinding, endptAddress);
        }

        // Handles operation errors.
        private static void HandleOperationErrors(OperationResult result)
        {
            string errorMessage = string.Empty;

            if (result.Errors.Count > 0)
            {
                foreach (Error anError in result.Errors)
                {
                    errorMessage += "Operation Error: " + anError.Code + ":" + anError.Description + "\n";
                }
                // Show the error messages.
                Console.WriteLine(errorMessage);
                // Throw an exception.
                throw new Exception(errorMessage);
            }
        }

        private static Identifier CreateModel(string modelName, string entityName, string explicitHierarchyName)
        {
            MetadataCreateRequest createRequest =
                new MetadataCreateRequest
                {
                    Metadata = new Metadata
                    {
                        Models = new Collection<Model>
                        {
                            new Model
                            {
                                Identifier = new Identifier {Name = modelName},
                                Entities = new Collection<Entity>
                                {
                                    new Entity
                                    {
                                        Identifier = new ModelContextIdentifier
                                        {
                                            Name = entityName,
                                            ModelId = new Identifier {Name = modelName}
                                        },
                                        ExplicitHierarchies = new Collection<ExplicitHierarchy>
                                        {
                                            new ExplicitHierarchy
                                            {
                                                Identifier = new EntityContextIdentifier
                                                {
                                                    Name = explicitHierarchyName,
                                                    ModelId = new Identifier {Name = modelName},
                                                    EntityId = new Identifier {Name = entityName}
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    },
                    ReturnCreatedIdentifiers = true
                };
            MetadataCreateResponse createResponse = clientProxy.MetadataCreate(createRequest);
            HandleOperationErrors(createResponse.OperationResult);
            return createResponse.MetadataCreated.Models[0].Identifier;
        }

        private static void DeleteModel(Identifier modelId)
        {
            MetadataDeleteRequest deleteRequest =
                new MetadataDeleteRequest
                {
                    Metadata = new Metadata
                    {
                        Models = new Collection<Model>
                        {
                            new Model
                            {
                                Identifier = modelId
                            }
                        }
                    }
                };
            MetadataDeleteResponse deleteResponse = clientProxy.MetadataDelete(deleteRequest);
            HandleOperationErrors(deleteResponse.OperationResult);
        }

        // Create an entity member with a specified name, code, and member type.
        // HierarchyName is used only when the member type is Consolidated.
        private static void CreateEntityMember(string modelName, string versionName, string entityName, string aNewMemberName, string aNewCode, MemberType memberType, string hierarchyName = null, string changesetName = null)
        {
            // Create the request object for entity creation.
            EntityMembersCreateRequest createRequest = new EntityMembersCreateRequest();
            createRequest.Members = new EntityMembers();
            createRequest.ReturnCreatedIdentifiers = true;
            // Set the modelId, versionId, and entityId.
            createRequest.Members.ModelId = new Identifier { Name = modelName };
            createRequest.Members.VersionId = new Identifier { Name = versionName };
            createRequest.Members.EntityId = new Identifier { Name = entityName };
            createRequest.Members.MemberType = memberType;
            createRequest.Members.Members = new Collection<Member> { };
            Member aNewMember = new Member();
            aNewMember.MemberId = new MemberIdentifier() { Name = aNewMemberName, Code = aNewCode, MemberType = memberType };

            if (memberType == MemberType.Consolidated)
            {
                // In case when the member type is consolidated set the parent information.
                // Set the hierarchy name and the parent code ("ROOT" means the root node of the hierarchy).
                aNewMember.Parents = new Collection<Parent> { };
                Parent aParent = new Parent();
                aParent.HierarchyId = new Identifier() { Name = hierarchyName };
                aParent.ParentId = new MemberIdentifier() { Code = "ROOT" };
                aNewMember.Parents.Add(aParent);
            }

            if (!string.IsNullOrEmpty(changesetName))
            {
                createRequest.Members.ChangesetId = new Identifier {Name = changesetName};
            }

            createRequest.Members.Members.Add(aNewMember);

            // Create a new entity member
            EntityMembersCreateResponse createResponse = clientProxy.EntityMembersCreate(createRequest);
            HandleOperationErrors(createResponse.OperationResult);

        }

        // Get the entity member identifier with specified model name, version name, entity name, member type, and entity member name.
        private static MemberIdentifier GetEntityMemberByName(string modelName, string versionName, string entityName, MemberType memberType, string memberName)
        {
            MemberIdentifier memberIdentifier = new MemberIdentifier();

            // Create the request object to get the entity information.
            EntityMembersGetRequest getRequest = new EntityMembersGetRequest();
            getRequest.MembersGetCriteria = new EntityMembersGetCriteria();

            // Set the modelId, versionId, entityId, and the member name.
            getRequest.MembersGetCriteria.ModelId = new Identifier { Name = modelName };
            getRequest.MembersGetCriteria.VersionId = new Identifier { Name = versionName };
            getRequest.MembersGetCriteria.EntityId = new Identifier { Name = entityName };
            getRequest.MembersGetCriteria.MemberType = memberType;
            getRequest.MembersGetCriteria.MemberReturnOption = MemberReturnOption.Data;
            getRequest.MembersGetCriteria.SearchTerm = "Name = '" + memberName + "'";

            // Get the entity member information
            EntityMembersGetResponse getResponse = clientProxy.EntityMembersGet(getRequest);

            // Get the entity member identifier.
            memberIdentifier = getResponse.EntityMembers.Members[0].MemberId;

            // Show attribute information.
            ShowMemberInformation(getResponse.EntityMembers.Members[0]);

            HandleOperationErrors(getResponse.OperationResult);

            return memberIdentifier;
        }

        // Get the entity member identifier with specified model name, version name, entity name, member type, and entity member code.
        private static MemberIdentifier GetEntityMemberByCode(string modelName, string versionName, string entityName, MemberType memberType, string memberCode)
        {
            MemberIdentifier memberIdentifier = new MemberIdentifier();

            // Create the request object to get the entity information.
            EntityMembersGetRequest getRequest = new EntityMembersGetRequest();
            getRequest.MembersGetCriteria = new EntityMembersGetCriteria();

            // Set the modelId, versionId, entityId, and the member code.
            getRequest.MembersGetCriteria.ModelId = new Identifier { Name = modelName };
            getRequest.MembersGetCriteria.VersionId = new Identifier { Name = versionName };
            getRequest.MembersGetCriteria.EntityId = new Identifier { Name = entityName };
            getRequest.MembersGetCriteria.MemberType = memberType;
            getRequest.MembersGetCriteria.MemberReturnOption = MemberReturnOption.Data;
            getRequest.MembersGetCriteria.SearchTerm = "Code = '" + memberCode + "'";

            // Get the entity member information
            EntityMembersGetResponse getResponse = clientProxy.EntityMembersGet(getRequest);

            // Get the entity member identifier.
            memberIdentifier = getResponse.EntityMembers.Members[0].MemberId;

            // Show attribute information.
            ShowMemberInformation(getResponse.EntityMembers.Members[0]);

            HandleOperationErrors(getResponse.OperationResult);

            return memberIdentifier;
        }

        private static Collection<Member> GetEntityMembers(string modelName, string versionName, string entityName, MemberType memberType, string changesetName)
        {
            // Create the request object to get the entity information.
            EntityMembersGetRequest getRequest = new EntityMembersGetRequest
            {
                MembersGetCriteria = new EntityMembersGetCriteria
                {
                    ModelId = new Identifier {Name = modelName},
                    VersionId = new Identifier {Name = versionName},
                    EntityId = new Identifier {Name = entityName},
                    MemberType = memberType,
                    MemberReturnOption = MemberReturnOption.Data
                }
            };

            if (!string.IsNullOrEmpty(changesetName))
            {
                getRequest.MembersGetCriteria.ChangesetId = new Identifier { Name = changesetName };
            }

            // Get the entity member information
            EntityMembersGetResponse getResponse = clientProxy.EntityMembersGet(getRequest);
            HandleOperationErrors(getResponse.OperationResult);

            foreach (var member in getResponse.EntityMembers.Members)
            {
                // Show attribute information.
                ShowMemberInformation(member);
            }

            return getResponse.EntityMembers.Members;
        }

        // Show attribute information.
        private static void ShowMemberInformation(Member member)
        {
            Console.WriteLine("Member Name:{0} Code: {1}", member.MemberId.Name, member.MemberId.Code);
            foreach (MDSTestService.Attribute anAttribute in member.Attributes)
            {
                string attributeType = string.Empty;
                switch (anAttribute.Type)
                {
                    case AttributeValueType.String:
                        attributeType = "String";
                        break;
                    case AttributeValueType.Number:
                        attributeType = "Number";
                        break;
                    case AttributeValueType.DateTime:
                        attributeType = "DateTime";
                        break;
                    case AttributeValueType.Domain:
                        attributeType = "Domain";
                        break;
                    case AttributeValueType.File:
                        attributeType = "File";
                        break;
                    default:
                        attributeType = "Not Specified";
                        break;
                }

                // Get the code value when the attribute is DBA.
                if (anAttribute.Type == AttributeValueType.Domain)
                {
                    MemberIdentifier dbaMemberId = (MemberIdentifier)anAttribute.Value;
                    Console.WriteLine("Attribute Name:{0} Attribute Type: {1} Attribute Value:{2}", anAttribute.Identifier.Name, attributeType, dbaMemberId.Code);
                }
                else
                {
                    Console.WriteLine("Attribute Name:{0} Attribute Type: {1} Attribute Value:{2}", anAttribute.Identifier.Name, attributeType, anAttribute.Value);
                }
            }
        }

        // Update an entity member (change name) with the member code.
        private static void UpdateEntityMember(string modelName, string versionName, string entityName, string memberCode, MemberType memberType, string newMemberName, string changesetName = null)
        {
            // Create the request object for entity update.
            EntityMembersUpdateRequest updateRequest = new EntityMembersUpdateRequest();
            updateRequest.Members = new EntityMembers();
            // Set the modelName, the versionName, and the entityName.
            updateRequest.Members.ModelId = new Identifier { Name = modelName };
            updateRequest.Members.VersionId = new Identifier { Name = versionName };
            updateRequest.Members.EntityId = new Identifier { Name = entityName };
            updateRequest.Members.MemberType = MemberType.Leaf;
            updateRequest.Members.Members = new Collection<Member> { };
            Member aMember = new Member();
            // Set the member code.
            aMember.MemberId = new MemberIdentifier() {Code = memberCode, MemberType = memberType};
            aMember.Attributes = new Collection<MDSTestService.Attribute> { };
            // Set the new member name into the Attribute object.
            MDSTestService.Attribute anAttribute = new MDSTestService.Attribute();
            anAttribute.Identifier = new Identifier() { Name = "Name" };
            anAttribute.Type = AttributeValueType.String;
            anAttribute.Value = newMemberName;
            aMember.Attributes.Add(anAttribute);
            updateRequest.Members.Members.Add(aMember);

            if (!string.IsNullOrEmpty(changesetName))
            {
                updateRequest.Members.ChangesetId = new Identifier { Name = changesetName };
            }

            // Update the entity member (change the name).
            EntityMembersUpdateResponse createResponse = clientProxy.EntityMembersUpdate(updateRequest);

            HandleOperationErrors(createResponse.OperationResult);

        }

        // Update an entity member relationship.
        private static void UpdateEntityMemberRelationship(string modelName, string versionName, string entityName, string hierarchyName, string parentMemberCode, string childMemberCode)
        {
            // Create the request object for entity update.
            EntityMembersUpdateRequest updateRequest = new EntityMembersUpdateRequest();
            updateRequest.Members = new EntityMembers();
            // Set the modelName, the versionName, and the entityName.
            updateRequest.Members.ModelId = new Identifier { Name = modelName };
            updateRequest.Members.VersionId = new Identifier { Name = versionName };
            updateRequest.Members.EntityId = new Identifier { Name = entityName };
            updateRequest.Members.MemberType = MemberType.Leaf;
            updateRequest.Members.Members = new Collection<Member> { };
            // Set child member information.
            Member aMember = new Member();
            aMember.MemberId = new MemberIdentifier() { Code = childMemberCode, MemberType = MemberType.Leaf };
            aMember.Attributes = new Collection<MDSTestService.Attribute> { };
            // Set parent member information.
            Parent aParent = new Parent();
            aParent.ParentId = new MemberIdentifier() { Code = parentMemberCode, MemberType = MemberType.Consolidated };
            aParent.HierarchyId = new Identifier() { Name = hierarchyName };
            aParent.RelationshipType = RelationshipType.Parent;
            aMember.Parents = new Collection<Parent> { };
            aMember.Parents.Add(aParent);

            updateRequest.Members.Members.Add(aMember);

            // Update the entity member relationship.
            EntityMembersUpdateResponse createResponse = clientProxy.EntityMembersUpdate(updateRequest);

            HandleOperationErrors(createResponse.OperationResult);

        }

        // Delete an entity member with the member code.
        private static void DeleteEntityMember(string modelName, string versionName, string entityName, string memberCode, MemberType memType, string changesetName = null)
        {
            // Create the request object for entity member deletion.
            EntityMembersDeleteRequest deleteRequest = new EntityMembersDeleteRequest();
            deleteRequest.Members = new EntityMembers();
            // Set the modelName, the versionName, and the entityName.
            deleteRequest.Members.ModelId = new Identifier { Name = modelName };
            deleteRequest.Members.VersionId = new Identifier { Name = versionName };
            deleteRequest.Members.EntityId = new Identifier { Name = entityName };
            deleteRequest.Members.MemberType = memType;
            deleteRequest.Members.Members = new Collection<Member> { };
            Member aMember = new Member();
            aMember.MemberId = new MemberIdentifier() { Code = memberCode, MemberType = memType };
            deleteRequest.Members.Members.Add(aMember);

            if (!string.IsNullOrEmpty(changesetName))
            {
                deleteRequest.Members.ChangesetId = new Identifier { Name = changesetName };
            }

            // Delete the entity member.
            EntityMembersDeleteResponse createResponse = clientProxy.EntityMembersDelete(deleteRequest);
            HandleOperationErrors(createResponse.OperationResult);

        }

        private static Identifier ChangesetSave(string modelName, string versionName, string entityName, Identifier changesetId,
            ChangesetStatus status)
        {
            var saveRequest = new EntityMemberChangesetSaveRequest
            {
                ModelId = new Identifier {Name = modelName},
                VersionId = new Identifier {Name = versionName},
                Changeset = new Changeset
                {
                    Identifier = changesetId,
                    EntityId = new Identifier {Name = entityName},
                    Status = status
                }
            };

            EntityMemberChangesetSaveResponse saveResponse = clientProxy.EntityMemberChangesetSave(saveRequest);
            HandleOperationErrors(saveResponse.OperationResult);
            return saveResponse.CreatedChangeset;
        }

        private static void ChangesetDelete(string modelName, string versionName, string name)
        {
            var deleteRequest = new EntityMemberChangesetDeleteRequest
            {
                ModelId = new Identifier { Name = modelName },
                VersionId = new Identifier { Name = versionName },
                ChangesetId = new Identifier { Name = name }
            };

            EntityMemberChangesetDeleteResponse deleteResponse = clientProxy.EntityMemberChangesetDelete(deleteRequest);
            HandleOperationErrors(deleteResponse.OperationResult);
        }

        private static void ChangesetsGet(string modelName, string versionName, string entityName, ChangesetStatus status = ChangesetStatus.NotSpecified)
        {
            var getRequest = new EntityMemberChangesetsGetRequest
            {
                ModelId = new Identifier { Name = modelName },
                VersionId = new Identifier { Name = versionName },
                EntityId = new Identifier { Name = entityName },
                Status = status
            };

            EntityMemberChangesetsGetResponse getResponse = clientProxy.EntityMemberChangesetsGet(getRequest);
            HandleOperationErrors(getResponse.OperationResult);
        }

        private static bool GetApprovalRequired(string modelName, string entityName)
        {
            var getRequest = new MetadataGetRequest
            {
                ResultOptions = new MetadataResultOptions
                {
                    Entities = ResultType.Identifiers
                },
                SearchCriteria = new MetadataSearchCriteria
                {
                    Models = new Collection<Identifier>
                    {
                        new Identifier {Name = modelName}
                    },
                    Entities = new Collection<Identifier>
                    {
                        new ModelContextIdentifier
                        {
                            Name = entityName,
                            ModelId = new Identifier {Name = modelName}
                        }
                    }
                }
            };

            return
                clientProxy.MetadataGet(getRequest)
                    .Metadata.Entities.Single()
                    .RequireApproval;
        }

        private static void SetApprovalRequired(string modelName, string entityName, bool approvalRequired)
        {
            var updateRequest = new MetadataUpdateRequest
            {
                Metadata = new Metadata
                {
                    Entities = new Collection<Entity>
                    {
                        new Entity
                        {
                            Identifier = new ModelContextIdentifier
                            {
                                Name = entityName,
                                ModelId = new Identifier {Name = modelName}
                            },
                            RequireApproval = approvalRequired
                        }
                    }
                }
            };

           MetadataUpdateResponse updateResponse = clientProxy.MetadataUpdate(updateRequest);
           HandleOperationErrors(updateResponse.OperationResult);
        }
    }
}
