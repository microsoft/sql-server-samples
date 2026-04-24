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
using System.ServiceModel;
using MetadataSample.MDSTestService; // For the created service reference.

namespace MetadataSample
{
    class Program
    {
        // MDS service client proxy object.
        private static ServiceClient clientProxy;
        // Set the MDS URL (plus /Service/Service.svc) here.
        private static string mdsURL = @"http://localhost/MDS/Service/Service.svc";

        static void Main(string[] args)
        {
            try
            {
                // Create a service proxy.
                clientProxy = GetClientProxy(mdsURL);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error creating a service proxy: {0}", ex);
                return;
            }

            // Create a model with a specified name.
            CreateModel("TestModel");

            // Get a model information with specified model and version names.
            // "VERSION_1" is a default version name for a new model.
            Identifier modelIdentifier = GetModel("TestModel", "VERSION_1");

            // Update the model name.
            UpdateModel(modelIdentifier.Id, "TestModelNew");

            // Create an entity with a specified name.
            CreateEntity(modelIdentifier.Id, "TestEntity");

            // Get an entity information with specified entity name and model id.
            ModelContextIdentifier entityIdentifier = GetEntity(modelIdentifier.Id, "TestEntity");

            // Update the entity name.
            UpdateEntity(modelIdentifier.Id, entityIdentifier.Id, "TestEntityNew");

            // Create an attribute with a specified name.
            CreateAttribute(modelIdentifier.Id, entityIdentifier.Id, "TestAttribute");

            // Get an attribute information with specified attribute name, model id, and entity id.
            ModelContextIdentifier attributeIdentifier = GetAttribute(modelIdentifier.Id, entityIdentifier.Id, "TestAttribute");

            // Update the attribute name.
            UpdateAttribute(modelIdentifier.Id, entityIdentifier.Id, attributeIdentifier.Id, "TestAttributeNew");

            // Create an attribute group with a specified name.
            CreateAttributeGroup(modelIdentifier.Id, entityIdentifier.Id, "TestAttributeGroup");

            // Get an attribute group information with specified attribute group name, model id, and entity id.
            ModelContextIdentifier attributeGroupIdentifier = GetAttributeGroup(modelIdentifier.Id, entityIdentifier.Id, "TestAttributeGroup");

            // Update the attribute group name and add an attribute to it.
            UpdateAttributeGroup(modelIdentifier.Id, entityIdentifier.Id, attributeGroupIdentifier.Id, "TestAttributeGroupNew", attributeIdentifier.Id);

            // Delete the attribute group with the specified attribute group id.
            DeleteAttributeGroup(attributeGroupIdentifier.Id);

            // Delete the attribute with the specified attribute id.
            DeleteAttribute(attributeIdentifier.Id);

            // Delete the entity with the specified entity id.
            DeleteEntity(entityIdentifier.Id);

            // Delete the model with the specified model id.
            DeleteModel(modelIdentifier.Id);

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
            }
        }

        // Create a model with a specified name.
        private static void CreateModel(string modelName)
        {
            try
            {
                // Create the request object for model creation.
                MetadataCreateRequest createRequest = new MetadataCreateRequest();
                createRequest.Metadata = new Metadata();
                createRequest.Metadata.Models = new System.Collections.ObjectModel.Collection<Model> { };
                Model newModel = new Model();
                newModel.Identifier = new Identifier { Name = modelName };
                createRequest.Metadata.Models.Add(newModel);

                // Create a new model.
                MetadataCreateResponse createResponse = clientProxy.MetadataCreate(createRequest);

                HandleOperationErrors(createResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }

        }

        // Get a model information (model identifier) with specified modle and version names.
        private static Identifier GetModel(string modelName, string versionName)
        {
            Identifier modelIdentifier = new Identifier();

            try
            {
                // Create the request object for getting model information.
                MetadataGetRequest getRequest = new MetadataGetRequest();
                getRequest.SearchCriteria = new MetadataSearchCriteria();
                getRequest.SearchCriteria.SearchOption = SearchOption.UserDefinedObjectsOnly;
                // Set the model and version names in the search criteria.
                getRequest.SearchCriteria.Models = new System.Collections.ObjectModel.Collection<Identifier> { new Identifier { Name = modelName } };
                getRequest.SearchCriteria.Versions = new System.Collections.ObjectModel.Collection<Identifier> { new Identifier { Name = versionName } };
                getRequest.ResultOptions = new MetadataResultOptions();
                getRequest.ResultOptions.Models = ResultType.Details;

                // Get a model information.
                MetadataGetResponse getResponse = clientProxy.MetadataGet(getRequest);

                if (getResponse.Metadata.Models.Count > 0)
                {
                    modelIdentifier = getResponse.Metadata.Models[0].Identifier;
                }

                HandleOperationErrors(getResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }

            return modelIdentifier;
        }

        // Update the model name.
        private static void UpdateModel(Guid modelId, string newModelName)
        {
            try
            {
                // Create the request object for updating model information.
                MetadataUpdateRequest updateRequest = new MetadataUpdateRequest();
                updateRequest.Metadata = new Metadata();
                updateRequest.Metadata.Models = new System.Collections.ObjectModel.Collection<Model> { };
                Model aModel = new Model();
                aModel.Identifier = new Identifier { Id = modelId, Name = newModelName };
                updateRequest.Metadata.Models.Add(aModel);

                // Update the model information.
                MetadataUpdateResponse updateResponse = clientProxy.MetadataUpdate(updateRequest);

                HandleOperationErrors(updateResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }
        }

        // Delete the model with the specified model id.
        private static void DeleteModel(Guid modelId)
        {
            try
            {
                // Create the request object for model deletion.
                MetadataDeleteRequest deleteRequest = new MetadataDeleteRequest();
                deleteRequest.Metadata = new Metadata();
                deleteRequest.Metadata.Models = new System.Collections.ObjectModel.Collection<Model> { };
                Model newModel = new Model();
                newModel.Identifier = new Identifier { Id = modelId };
                deleteRequest.Metadata.Models.Add(newModel);

                // Delete the specified model
                MetadataDeleteResponse deleteResponse = clientProxy.MetadataDelete(deleteRequest);

                HandleOperationErrors(deleteResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }

        }

        // Create an entity with a specified name.
        private static void CreateEntity(Guid modelId, string entityName)
        {
            try
            {
                // Create the request object for entity creation.
                MetadataCreateRequest createRequest = new MetadataCreateRequest();
                createRequest.Metadata = new Metadata();
                createRequest.Metadata.Entities = new System.Collections.ObjectModel.Collection<Entity> { };
                Entity newEntity = new Entity();
                // Set the modelId and the entity name.
                newEntity.Identifier = new ModelContextIdentifier { Name = entityName, ModelId = new Identifier { Id = modelId } };
                createRequest.Metadata.Entities.Add(newEntity);

                // Create a new entity
                MetadataCreateResponse createResponse = clientProxy.MetadataCreate(createRequest);

                HandleOperationErrors(createResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }

        }

        // Get an entity information (ModelContextIdentifier for the entity) with specified entity name and model id.
        private static ModelContextIdentifier GetEntity(Guid modelId, string entityName)
        {
            ModelContextIdentifier entityIdentifier = new ModelContextIdentifier();

            try
            {
                // Create the request object for getting entity information.
                MetadataGetRequest getRequest = new MetadataGetRequest();
                getRequest.SearchCriteria = new MetadataSearchCriteria();
                getRequest.SearchCriteria.SearchOption = SearchOption.UserDefinedObjectsOnly;
                // Set the entity name and model id
                getRequest.SearchCriteria.Entities = new System.Collections.ObjectModel.Collection<Identifier> { new Identifier { Name = entityName } };
                getRequest.SearchCriteria.Models = new System.Collections.ObjectModel.Collection<Identifier> { new Identifier { Id = modelId } };
                getRequest.ResultOptions = new MetadataResultOptions();
                getRequest.ResultOptions.Entities = ResultType.Details;
                // Get an entity information.
                MetadataGetResponse getResponse = clientProxy.MetadataGet(getRequest);

                if (getResponse.Metadata.Entities.Count > 0)
                {
                    entityIdentifier = getResponse.Metadata.Entities[0].Identifier;
                }

                HandleOperationErrors(getResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }

            return entityIdentifier;
        }

        // Update the entity name.
        private static void UpdateEntity(Guid modelId, Guid entityId, string newEntityName)
        {
            try
            {
                // Create the request object for updating entity information.
                MetadataUpdateRequest updateRequest = new MetadataUpdateRequest();
                updateRequest.Metadata = new Metadata();
                updateRequest.Metadata.Entities = new System.Collections.ObjectModel.Collection<Entity> { };
                Entity anEntity = new Entity();

                // Set model id, entity id, and the new entity name.
                anEntity.Identifier = new ModelContextIdentifier { Id = entityId, Name = newEntityName, ModelId = new Identifier { Id = modelId } };
                updateRequest.Metadata.Entities.Add(anEntity);

                // Update the entity information.
                MetadataUpdateResponse updateResponse = clientProxy.MetadataUpdate(updateRequest);

                HandleOperationErrors(updateResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }
        }

        // Delete the entity with the specified entity id.
        private static void DeleteEntity(Guid entityId)
        {
            try
            {
                // Create the request object for entity deletion.
                MetadataDeleteRequest deleteRequest = new MetadataDeleteRequest();
                deleteRequest.Metadata = new Metadata();
                deleteRequest.Metadata.Entities = new System.Collections.ObjectModel.Collection<Entity> { };
                Entity anEntity = new Entity();
                anEntity.Identifier = new ModelContextIdentifier { Id = entityId };
                deleteRequest.Metadata.Entities.Add(anEntity);

                // Delete the specified entity
                MetadataDeleteResponse deleteResponse = clientProxy.MetadataDelete(deleteRequest);

                HandleOperationErrors(deleteResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }

        }


        // Create an attribute with a specified name.
        private static void CreateAttribute(Guid modelId, Guid entityId, string attributeName)
        {
            try
            {
                // Create the request object for attribute creation.
                MetadataCreateRequest createRequest = new MetadataCreateRequest();
                createRequest.Metadata = new Metadata();
                createRequest.Metadata.Attributes = new System.Collections.ObjectModel.Collection<MetadataAttribute> { };
                MetadataAttribute newAttribute = new MetadataAttribute();
                // Set model id, entity id, and attribute name.
                newAttribute.Identifier = new MemberTypeContextIdentifier { Name = attributeName, ModelId = new Identifier { Id = modelId }, EntityId = new Identifier { Id = entityId }, MemberType = MemberType.Leaf };
                newAttribute.AttributeType = AttributeType.FreeForm;
                newAttribute.DataType = AttributeDataType.Text;
                // When the DataType is "Text", set the length (100) to DataTypeInformation.
                newAttribute.DataTypeInformation = 100;
                newAttribute.DisplayWidth = 100;
                createRequest.Metadata.Attributes.Add(newAttribute);

                // Create a new attribute
                MetadataCreateResponse createResponse = clientProxy.MetadataCreate(createRequest);

                HandleOperationErrors(createResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }

        }

        // Get an attribute information (ModelContextIdentifier for the attribute) with specified attribute name, model id, and entity id.
        private static ModelContextIdentifier GetAttribute(Guid modelId, Guid entityId, string attributeName)
        {
            ModelContextIdentifier AttributeIdentifier = new ModelContextIdentifier();

            try
            {
                // Create the request object for getting attribute information.
                MetadataGetRequest getRequest = new MetadataGetRequest();
                getRequest.SearchCriteria = new MetadataSearchCriteria();
                getRequest.SearchCriteria.SearchOption = SearchOption.UserDefinedObjectsOnly;
                // Set model id, entity id, and attribute name.
                getRequest.SearchCriteria.Attributes = new System.Collections.ObjectModel.Collection<Identifier> { new Identifier { Name = attributeName } };
                getRequest.SearchCriteria.Entities = new System.Collections.ObjectModel.Collection<Identifier> { new Identifier { Id = entityId } };
                getRequest.SearchCriteria.Models = new System.Collections.ObjectModel.Collection<Identifier> { new Identifier { Id = modelId } };
                getRequest.ResultOptions = new MetadataResultOptions();
                getRequest.ResultOptions.Attributes = ResultType.Details;

                // Get an attribute information.
                MetadataGetResponse getResponse = clientProxy.MetadataGet(getRequest);

                if (getResponse.Metadata.Attributes.Count > 0)
                {
                    AttributeIdentifier = getResponse.Metadata.Attributes[0].Identifier;
                }

                HandleOperationErrors(getResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }

            return AttributeIdentifier;
        }

        // Update the attribute name.
        private static void UpdateAttribute(Guid modelId, Guid entityId, Guid attributeId, string newAttributeName)
        {
            try
            {
                // Create the request object for updating attribute information.
                MetadataUpdateRequest updateRequest = new MetadataUpdateRequest();
                updateRequest.Metadata = new Metadata();
                updateRequest.Metadata.Attributes = new System.Collections.ObjectModel.Collection<MetadataAttribute> { };
                // Set model id, entity id, attribute id, and new attribute name.
                MetadataAttribute anAttribute = new MetadataAttribute { Identifier = new MemberTypeContextIdentifier { Name = newAttributeName, Id = attributeId, ModelId = new Identifier { Id = modelId }, EntityId = new Identifier { Id = entityId }, MemberType = MDSTestService.MemberType.Leaf } };
                updateRequest.Metadata.Attributes.Add(anAttribute);

                // Update the attribute information.
                MetadataUpdateResponse updateResponse = clientProxy.MetadataUpdate(updateRequest);

                HandleOperationErrors(updateResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }
        }

        // Delete an attribute with the specified attribute id.
        private static void DeleteAttribute(Guid attributeId)
        {
            try
            {
                // Create the request object for attribute deletion.
                MetadataDeleteRequest deleteRequest = new MetadataDeleteRequest();
                deleteRequest.Metadata = new Metadata();
                deleteRequest.Metadata.Attributes = new System.Collections.ObjectModel.Collection<MetadataAttribute> { };
                MetadataAttribute anAttribute = new MetadataAttribute();
                // Set the attribute id.
                anAttribute.Identifier = new MemberTypeContextIdentifier { Id = attributeId };
                deleteRequest.Metadata.Attributes.Add(anAttribute);

                // Delete a specified attribute
                MetadataDeleteResponse deleteResponse = clientProxy.MetadataDelete(deleteRequest);

                HandleOperationErrors(deleteResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }

        }

        // Create an attribute group with a specified name.
        private static void CreateAttributeGroup(Guid modelId, Guid entityId, string attributeGroupName)
        {
            try
            {
                // Create the request object for attribute group creation.
                MetadataCreateRequest createRequest = new MetadataCreateRequest();
                createRequest.Metadata = new Metadata();
                createRequest.Metadata.AttributeGroups = new System.Collections.ObjectModel.Collection<AttributeGroup> { };
                AttributeGroup newAttributeGroup = new AttributeGroup();
                // Set model id, entity id, and attribute group name.
                newAttributeGroup.Identifier = new MemberTypeContextIdentifier { Name = attributeGroupName, ModelId = new Identifier { Id = modelId }, EntityId = new Identifier { Id = entityId }, MemberType = MemberType.Leaf };
                newAttributeGroup.FullName = attributeGroupName;
                createRequest.Metadata.AttributeGroups.Add(newAttributeGroup);

                // Create a new attribute group.
                MetadataCreateResponse createResponse = clientProxy.MetadataCreate(createRequest);

                HandleOperationErrors(createResponse.OperationResult);

            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }

        }

        // Get an attribute group information (ModelContextIdentifier for the attribute group) with specified attribute group name, model id, and entity id.
        private static ModelContextIdentifier GetAttributeGroup(Guid modelId, Guid entityId, string attributeGroupName)
        {
            ModelContextIdentifier AttributeGroupIdentifier = new ModelContextIdentifier();

            try
            {
                // Create the request object for getting attribute group information.
                MetadataGetRequest getRequest = new MetadataGetRequest();
                getRequest.SearchCriteria = new MetadataSearchCriteria();
                getRequest.SearchCriteria.SearchOption = SearchOption.UserDefinedObjectsOnly;
                // Set model id, entity id, and attribute group name.
                getRequest.SearchCriteria.Models = new System.Collections.ObjectModel.Collection<Identifier> { new Identifier { Id = modelId } };
                getRequest.SearchCriteria.Entities = new System.Collections.ObjectModel.Collection<Identifier> { new Identifier { Id = entityId } };
                getRequest.SearchCriteria.AttributeGroups = new System.Collections.ObjectModel.Collection<Identifier> { new Identifier { Name = attributeGroupName } };
                getRequest.ResultOptions = new MetadataResultOptions();
                getRequest.ResultOptions.AttributeGroups = ResultType.Details;

                // Get an attribute group information.
                MetadataGetResponse getResponse = clientProxy.MetadataGet(getRequest);

                if (getResponse.Metadata.AttributeGroups.Count > 0)
                {
                    AttributeGroupIdentifier = getResponse.Metadata.AttributeGroups[0].Identifier;
                }

                HandleOperationErrors(getResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }

            return AttributeGroupIdentifier;
        }

        // Update the attribute group name and add an attribute to it.
        private static void UpdateAttributeGroup(Guid modelId, Guid entityId, Guid attributeGroupId, string newAttributeGroupName, Guid attributeId)
        {
            try
            {
                // Create the request object for updating attribute group information.
                MetadataUpdateRequest updateRequest = new MetadataUpdateRequest();
                updateRequest.Metadata = new Metadata();
                updateRequest.Metadata.AttributeGroups = new System.Collections.ObjectModel.Collection<AttributeGroup> { };
                // Set model id, entity id, attribute group id, and new attribute group name.
                AttributeGroup anAttributeGroup = new AttributeGroup { Identifier = new MemberTypeContextIdentifier { Name = newAttributeGroupName, Id = attributeGroupId, ModelId = new Identifier { Id = modelId }, EntityId = new Identifier { Id = entityId }, MemberType = MDSTestService.MemberType.Leaf } };
                // Add the attribute object with the attribute id.
                anAttributeGroup.Attributes = new System.Collections.ObjectModel.Collection<MetadataAttribute> { };
                MetadataAttribute anAttribute = new MetadataAttribute { Identifier = new MemberTypeContextIdentifier { Id = attributeId } };
                anAttributeGroup.Attributes.Add(anAttribute);
                updateRequest.Metadata.AttributeGroups.Add(anAttributeGroup);

                // Update the attribute group information.
                MetadataUpdateResponse updateResponse = clientProxy.MetadataUpdate(updateRequest);

                HandleOperationErrors(updateResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }
        }

        // Delete the attribute group with the specified attribute group id.
        private static void DeleteAttributeGroup(Guid attributeGroupId)
        {
            try
            {
                // Create the request object for attribute group deletion.
                MetadataDeleteRequest deleteRequest = new MetadataDeleteRequest();
                deleteRequest.Metadata = new Metadata();
                deleteRequest.Metadata.AttributeGroups = new System.Collections.ObjectModel.Collection<AttributeGroup> { };
                AttributeGroup anAttributeGroup = new AttributeGroup();
                // Set attribute group id.
                anAttributeGroup.Identifier = new MemberTypeContextIdentifier { Id = attributeGroupId };
                deleteRequest.Metadata.AttributeGroups.Add(anAttributeGroup);

                // Delete the specified attribute group.
                MetadataDeleteResponse deleteResponse = clientProxy.MetadataDelete(deleteRequest);

                HandleOperationErrors(deleteResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }

        }

    }
}
