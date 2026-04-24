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
using System.Threading;
using System.ServiceModel;
using EntityBasedStaging.MDSTestService; // For the created service reference.

namespace EntityBasedStaging
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
                // Before running this sample code you need to populate the staging table for the entity that you use with a staging record.
                // The staging record should have batch tag = "Test1".
                // Example:
                // Populate the record into stg.TestEntity_Leaf staging table with batch tag = “Test1” by running the SQL script.
                // Note that the Code and Name below is set to trigger the business rule validation error (if Code is “ABC”, Name must be equal to “Test”).
                // Insert into stg.TestEntity_Leaf
                // (ImportType, BatchTag, Code, Name)
                // values (0, N'Test1', N'ABC', N'Name2');
                // ImportType = 0 means the import type is merge optimistic.

                // Create a service proxy.
                clientProxy = GetClientProxy(mdsURL);

                // Process staging data in the staging table with the specified batch tag.
                // You need to specify the existing model name, entity name, version name, and batch tag.
                ProcessStagingData("TestModel", "TestEntity", "VERSION_1", "Test1", MemberType.Leaf);

                // Wait till the batch process completes (wait for 60 seconds).
                Thread.Sleep(60000);

                // Get the staging information such as the batch status and the error information.
                // In this example GetStagingInformation method returns the batch id for the specified batch tag.
                // You need to specify the existing model name and batch tag.
                int batchId = GetStagingInformation("TestModel", "Test1");

                // Clear the batch staging data for the specified batch id.
                // This is the step to set the batch status as "Cleared" and remove the staging records from the staging table for the batch id.
                ClearStagingData("TestModel", batchId);

                // The followings are to validate the record that is added by Entity Based Staging.
                // Create a new business rule and publish the rule to enable it in the validation process.
                // You need to specify the existing model and entity names.
                CreateAndPublishBR("TestModel", "TestEntity", "Rule1");

                // Process the validation and get the list of validation issues.
                // You need to specify the existing model, entity, and version names.
                GetBRValidationIssue("TestModel", "TestEntity", "Rule1", "VERSION_1");

            }
            catch (Exception ex)
            {
                Console.WriteLine("Error creating a service proxy: {0}", ex);
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

        // Process staging data in the staging table with the specified batch tag.
        private static void ProcessStagingData(string modelName, string entityName, string versionName, string batchTag, MemberType memberType)
        {
            try
            {
                // Set model, entity, and version objects.
                MDSTestService.Identifier modelId = new MDSTestService.Identifier { Name = modelName };
                MDSTestService.Identifier entityId = new MDSTestService.Identifier { Name = entityName };
                MDSTestService.Identifier versionId = new MDSTestService.Identifier { Name = versionName };

                // Get entity MUID.
                MetadataGetRequest getRequest = new MetadataGetRequest();
                getRequest.SearchCriteria = new MetadataSearchCriteria();
                getRequest.SearchCriteria.Models = new System.Collections.ObjectModel.Collection<Identifier> { };
                getRequest.SearchCriteria.Models.Add(modelId);
                getRequest.SearchCriteria.Entities = new System.Collections.ObjectModel.Collection<Identifier> { };
                getRequest.SearchCriteria.Entities.Add(entityId);
                getRequest.SearchCriteria.Versions = new System.Collections.ObjectModel.Collection<Identifier> { };
                getRequest.SearchCriteria.Versions.Add(versionId);
                getRequest.SearchCriteria.SearchOption = SearchOption.BothUserDefinedAndSystemObjects;

                getRequest.ResultOptions = new MetadataResultOptions();
                getRequest.ResultOptions.Entities = ResultType.Identifiers;
                getRequest.ResultOptions.Versions = ResultType.Identifiers;

                MetadataGetResponse getResponse = clientProxy.MetadataGet(getRequest);
                HandleOperationErrors(getResponse.OperationResult);

                // Set entity MUID since it cannot be specified only by name.
                entityId.Id = getResponse.Metadata.Entities[0].Identifier.Id;

                // Set entity MUID since it cannot be specified only by name.
                versionId.Id = getResponse.Metadata.Versions[0].Identifier.Id;
                // Create the request object.
                MDSTestService.EntityStagingProcessRequest processRequest = new EntityStagingProcessRequest();
                processRequest.BatchTag = batchTag;
                processRequest.EntityId = entityId;
                processRequest.VersionId = versionId;
                processRequest.MemberType = MemberType.Leaf;

                // Process staging data.
                MDSTestService.EntityStagingProcessResponse processResponse = clientProxy.EntityStagingProcess(processRequest);

                HandleOperationErrors(processResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }
        }

        // Get the staging information such as batch status and the error information.
        // In this example returns the batch id for the specified batch tag.
        private static int GetStagingInformation(string modelName, string batchTag)
        {
            int batchId = -1;

            try
            {
                // Set model object.
                MDSTestService.Identifier modelId = new MDSTestService.Identifier { Name = modelName };

                // Create the request object.
                // Get batch information for the specified model.
                MDSTestService.EntityStagingGetRequest getInfoRequest = new EntityStagingGetRequest();
                EntityStagingGetCriteria getCriteria = new EntityStagingGetCriteria();
                getCriteria.ModelId = modelId;
                getCriteria.IncludeClearedBatches = false;
                getInfoRequest.GetCriteria = getCriteria;

                MDSTestService.EntityStagingGetResponse getInfoResponse = clientProxy.EntityStagingGet(getInfoRequest);

                HandleOperationErrors(getInfoResponse.OperationResult);

                // Find the batch id (the last one) for the specified batch tag.
                foreach (EntityStagingBatch aBatch in getInfoResponse.Batches)
                {
                    if (string.Equals(aBatch.BatchTag, batchTag, StringComparison.OrdinalIgnoreCase))
                    {
                        batchId = aBatch.BatchId.Value;
                        // You can also access the error information or the batch status.
                        // aBatch.ErrorView
                        // aBatch.Status
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }

            return batchId;
        }

        // Clear the batch staging data for the specified batch id.
        private static void ClearStagingData(string modelName, int batchId)
        {
            try
            {
                // Set model and batch objects.
                MDSTestService.Identifier modelId = new MDSTestService.Identifier { Name = modelName };

                // Create the request object.
                MDSTestService.EntityStagingClearRequest clearRequest = new EntityStagingClearRequest();
                clearRequest.ModelId = modelId;
                clearRequest.BatchId = batchId;

                // Clear the batch staging data.
                MDSTestService.EntityStagingClearResponse processResponse = clientProxy.EntityStagingClear(clearRequest);

                HandleOperationErrors(processResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }
        }

        // Create a new business rule and publish the rule to enable it in the validation process.
        private static void CreateAndPublishBR(string modelName, string entityName, string ruleName)
        {
            try
            {
                // Set Model and Entity objects.
                Identifier modelId = new Identifier { Name = modelName };
                Identifier entityId = new Identifier { Name = entityName };

                // Create the request object.
                MDSTestService.BusinessRulesCreateRequest ruleCreateRequest = new MDSTestService.BusinessRulesCreateRequest();
                ruleCreateRequest.ReturnCreatedIdentifiers = true;
                ruleCreateRequest.BusinessRuleSet = new MDSTestService.BusinessRules();

                // Create a new business rule.
                BusinessRule newRule = new BusinessRule();
                ruleCreateRequest.BusinessRuleSet.BusinessRulesMember = new System.Collections.ObjectModel.Collection<BusinessRule> { };
                ruleCreateRequest.BusinessRuleSet.BusinessRulesMember.Add(newRule);

                newRule.Identifier = new MemberTypeContextIdentifier
                {
                    Name = ruleName,
                    ModelId = modelId,
                    EntityId = entityId,
                    MemberType = MemberType.Leaf
                };

                newRule.Priority = 10;
                newRule.BRConditionTree = new BRConditionTreeNode();
                newRule.BRConditionTree.LogicalOperator = LogicalOperator.And;
                newRule.BRConditionTree.Sequence = 1;

                // Create the rule condition "Code equals ABC".
                BRCondition ruleCondition = new BRCondition();
                newRule.BRConditionTree.BRConditions = new System.Collections.ObjectModel.Collection<BRCondition> { };
                newRule.BRConditionTree.BRConditions.Add(ruleCondition);
                ruleCondition.Sequence = 1;

                // Create the condition prefix argument for Code attribute.
                BRAttributeArgument conditionPrefix = new BRAttributeArgument();
                ruleCondition.PrefixArgument = conditionPrefix;
                conditionPrefix.PropertyName = BRPropertyName.Anchor;
                conditionPrefix.AttributeId = new Identifier { Name = "Code" };

                // Set the condition operator.
                ruleCondition.Operator = BRItemType.IsEqual;

                // Set the postfix argument "ABC".
                BRFreeformArgument conditionPostfix = new BRFreeformArgument();
                ruleCondition.PostfixArguments = new System.Collections.ObjectModel.Collection<object> { };
                ruleCondition.PostfixArguments.Add(conditionPostfix);
                conditionPostfix.PropertyName = BRPropertyName.Value;
                conditionPostfix.Value = "ABC";

                // Create the rule action "Name must be equal to Test".
                BRAction ruleAction = new BRAction();
                newRule.BRActions = new System.Collections.ObjectModel.Collection<BRAction> { };
                newRule.BRActions.Add(ruleAction);
                ruleAction.Sequence = 1;

                // Set the action prefix argument for Name attribute.
                BRAttributeArgument actionPrefix = new BRAttributeArgument();
                ruleAction.PrefixArgument = actionPrefix;
                actionPrefix.PropertyName = BRPropertyName.Anchor;
                actionPrefix.AttributeId = new Identifier { Name = "Name" };

                // Set the action operator.
                ruleAction.Operator = BRItemType.MustBeEqual;

                // Set the action postfix argument.
                BRFreeformArgument actionPostfix = new BRFreeformArgument();
                ruleAction.PostfixArguments = new System.Collections.ObjectModel.Collection<object> { };
                ruleAction.PostfixArguments.Add(actionPostfix);
                actionPostfix.PropertyName = BRPropertyName.Value;
                actionPostfix.Value = "Test";

                // Create the business rule.
                MDSTestService.BusinessRulesCreateResponse ruleCreateResponse = clientProxy.BusinessRulesCreate(ruleCreateRequest);

                HandleOperationErrors(ruleCreateResponse.OperationResult);

                // Create the request object.
                MDSTestService.BusinessRulesPublishRequest rulePublishRequest = new MDSTestService.BusinessRulesPublishRequest();
                rulePublishRequest.BRPublishCriteria = new BRPublishCriteria();
                rulePublishRequest.BRPublishCriteria.EntityId = entityId;
                rulePublishRequest.BRPublishCriteria.ModelId = modelId;
                rulePublishRequest.BRPublishCriteria.MemberType = BREntityMemberType.Leaf;

                // Publish the business rule.
                MDSTestService.MessageResponse rulePublishResponse = clientProxy.BusinessRulesPublish(rulePublishRequest);

                HandleOperationErrors(rulePublishResponse.OperationResult);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }
        }

        // Process the validation and get the list of validation issues.
        private static void GetBRValidationIssue(string modelName, string entityName, string ruleName, string versionName)
        {
            try
            {
                // Set Model, Entity, and Version objects.
                Identifier modelId = new Identifier { Name = modelName };
                Identifier entityId = new Identifier { Name = entityName };
                Identifier versionId = new Identifier { Name = versionName };

                // Create the request object.
                MDSTestService.ValidationProcessRequest validationProcessRequest = new MDSTestService.ValidationProcessRequest();
                validationProcessRequest.ValidationProcessCriteria = new ValidationProcessCriteria();
                validationProcessRequest.ValidationProcessCriteria.ModelId = modelId;
                validationProcessRequest.ValidationProcessCriteria.EntityId = entityId;
                validationProcessRequest.ValidationProcessCriteria.VersionId = versionId;
                validationProcessRequest.ValidationProcessOptions = new ValidationProcessOptions();
                validationProcessRequest.ValidationProcessOptions.ReturnValidationResults = true;

                // Process validation and get a validation issue.
                MDSTestService.ValidationProcessResponse validationProcessResponse = clientProxy.ValidationProcess(validationProcessRequest);
                HandleOperationErrors(validationProcessResponse.OperationResult);

                // Show the validation issue's description.
                if (validationProcessResponse.ValidationIssueList.Count > 0)
                {
                    ValidationIssue validationIssue = validationProcessResponse.ValidationIssueList[0];
                    Console.WriteLine("Validation issue: " + validationIssue.Description);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {0}", ex);
            }
        }

    }
}
