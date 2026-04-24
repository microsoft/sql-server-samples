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
using MDSBusinessRules.MDSTestService; // For the created service reference.

namespace MDSBusinessRules
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

            // Create a new business rule and publish it.
            // You need to specify the existing Model and Entity names.
            CreateAndPublishBR("TestModel", "TestEntity", "Test Rule");

            // Edits the business rule and publishes it.
            EditAndPublishBR("TestModel", "TestEntity", "Test Rule");

            // Creates a member that causes a validation issue, processes the validation and gets the list of validation issues.
            // You need to specify the existing Model, Entity, and Version names.
            GetBRValidationIssue("TestModel", "TestEntity", "Test Rule", "VERSION_1");

            // Excludes the business rule and publishes it.
            ExcludeAndPublishBR("TestModel", "TestEntity", "Test Rule");

            // Deletes the business rule and publishes it.
            DeleteAndPublishBR("TestModel", "TestEntity", "Test Rule");

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
                ruleCreateRequest.BusinessRuleSet = new BusinessRules();

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

        // Edits the business rule and publish to enable the changes in the validation process.
        private static void EditAndPublishBR(string modelName, string entityName, string ruleName)
        {
            try
            {
                // Set Model and Entity objects.
                Identifier modelId = new Identifier { Name = modelName };
                Identifier entityId = new Identifier { Name = entityName };

                // Create the request object.
                MDSTestService.BusinessRulesGetRequest ruleGetRequest = new MDSTestService.BusinessRulesGetRequest();
                ruleGetRequest.ResultOptions = new BRResultOptions();
                ruleGetRequest.ResultOptions.BusinessRules = ResultType.Details;
                ruleGetRequest.GetCriteria = new BRGetCriteria();
                ruleGetRequest.GetCriteria.ModelId = modelId;
                ruleGetRequest.GetCriteria.EntityId = entityId;
                ruleGetRequest.GetCriteria.MemberType = BREntityMemberType.Leaf;
                ruleGetRequest.GetCriteria.BusinessRuleIds = new System.Collections.ObjectModel.Collection<Identifier> { };
                ruleGetRequest.GetCriteria.BusinessRuleIds.Add(new Identifier { Name = ruleName });

                // Get the business rules.
                MDSTestService.BusinessRulesGetResponse ruleGetResponse = clientProxy.BusinessRulesGet(ruleGetRequest);
                HandleOperationErrors(ruleGetResponse.OperationResult);

                BusinessRule selectedBusinessRule = ruleGetResponse.BusinessRuleSet.BusinessRulesMember[0];

                // Change the condition to "Code starts with Test".
                BRCondition ruleCondition = selectedBusinessRule.BRConditionTree.BRConditions[0];

                // Set the attribute name as "Code".
                BRAttributeArgument conditionPrefix = (BRAttributeArgument)ruleCondition.PrefixArgument;
                conditionPrefix.PropertyName = BRPropertyName.Anchor;
                conditionPrefix.AttributeId = new Identifier { Name = "Code" };

                // Set the condition operator.
                ruleCondition.Operator = BRItemType.StartsWith;

                // Set the postfix argument "Test".
                BRFreeformArgument conditionPostfix = (BRFreeformArgument)ruleCondition.PostfixArguments[0];

                conditionPostfix.PropertyName = BRPropertyName.Value;
                conditionPostfix.Value = "Test";

                // Create the request object.
                MDSTestService.BusinessRulesUpdateRequest ruleUpdateRequest = new MDSTestService.BusinessRulesUpdateRequest();
                ruleUpdateRequest.BusinessRuleSet = ruleGetResponse.BusinessRuleSet;

                // Update the business rule.
                MDSTestService.MessageResponse ruleUpdateResponse = clientProxy.BusinessRulesUpdate(ruleUpdateRequest);
                HandleOperationErrors(ruleUpdateResponse.OperationResult);

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

        // Creates a member that causes a validation issue, processes the validation and gets the list of validation issues.
        private static void GetBRValidationIssue(string modelName, string entityName, string ruleName, string versionName)
        {
            try
            {
                // Set Model, Entity, and Version objects.
                Identifier modelId = new Identifier { Name = modelName };
                Identifier entityId = new Identifier { Name = entityName };
                Identifier versionId = new Identifier { Name = versionName };

                // Create the request object.
                MDSTestService.BusinessRulesCreateRequest ruleCreateRequest = new MDSTestService.BusinessRulesCreateRequest();
                ruleCreateRequest.ReturnCreatedIdentifiers = true;
                ruleCreateRequest.BusinessRuleSet = new BusinessRules();

                // Create the request object.
                MDSTestService.EntityMembersCreateRequest memberCreateRequest = new MDSTestService.EntityMembersCreateRequest();
                memberCreateRequest.Members = new EntityMembers();
                memberCreateRequest.Members.ModelId = modelId;
                memberCreateRequest.Members.EntityId = entityId;
                memberCreateRequest.Members.VersionId = versionId;
                memberCreateRequest.Members.MemberType = MemberType.Leaf;
                Member aMember = new Member();
                aMember.MemberId = new MemberIdentifier();
                aMember.MemberId.Code = "Test12";
                aMember.MemberId.Name = "AA";
                aMember.MemberId.MemberType = MemberType.Leaf;
                memberCreateRequest.Members.Members = new System.Collections.ObjectModel.Collection<Member> { };
                memberCreateRequest.Members.Members.Add(aMember);

                // Add a member that triggers the validation error.
                MDSTestService.EntityMembersCreateResponse memberCreateResponse = clientProxy.EntityMembersCreate(memberCreateRequest);
                HandleOperationErrors(memberCreateResponse.OperationResult);

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

        // Excludes the business rule and publishes it to remove the rule from the validation process.
        private static void ExcludeAndPublishBR(string modelName, string entityName, string ruleName)
        {
            try
            {
                // Set Model and Entity objects.
                Identifier modelId = new Identifier { Name = modelName };
                Identifier entityId = new Identifier { Name = entityName };

                // Create the request object.
                MDSTestService.BusinessRulesGetRequest ruleGetRequest = new MDSTestService.BusinessRulesGetRequest();
                ruleGetRequest.ResultOptions = new BRResultOptions();
                ruleGetRequest.ResultOptions.BusinessRules = ResultType.Details;
                ruleGetRequest.GetCriteria = new BRGetCriteria();
                ruleGetRequest.GetCriteria.ModelId = modelId;
                ruleGetRequest.GetCriteria.EntityId = entityId;
                ruleGetRequest.GetCriteria.MemberType = BREntityMemberType.Leaf;
                ruleGetRequest.GetCriteria.BusinessRuleIds = new System.Collections.ObjectModel.Collection<Identifier> { };
                ruleGetRequest.GetCriteria.BusinessRuleIds.Add(new Identifier { Name = ruleName });

                // Get the business rules.
                MDSTestService.BusinessRulesGetResponse ruleGetResponse = clientProxy.BusinessRulesGet(ruleGetRequest);
                HandleOperationErrors(ruleGetResponse.OperationResult);

                BusinessRule selectedBusinessRule = ruleGetResponse.BusinessRuleSet.BusinessRulesMember[0];

                // Set the status to pending exclusion.
                selectedBusinessRule.Status = BRStatus.PendingExclusion;

                // Create the request object.
                MDSTestService.BusinessRulesUpdateRequest ruleUpdateRequest = new MDSTestService.BusinessRulesUpdateRequest();
                ruleUpdateRequest.BusinessRuleSet = new BusinessRules();
                ruleUpdateRequest.BusinessRuleSet.BusinessRulesMember = new System.Collections.ObjectModel.Collection<BusinessRule> { };
                ruleUpdateRequest.BusinessRuleSet.BusinessRulesMember.Add(selectedBusinessRule);

                // Update the business rule's status to pending exclusion.
                MDSTestService.MessageResponse ruleUpdateResponse = clientProxy.BusinessRulesUpdate(ruleUpdateRequest);

                HandleOperationErrors(ruleUpdateResponse.OperationResult);

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

        // Deletes the business rule and publishes to remove the rule from the validation process.
        private static void DeleteAndPublishBR(string modelName, string entityName, string ruleName)
        {
            try
            {
                // Set Model and Entity objects.
                Identifier modelId = new Identifier { Name = modelName };
                Identifier entityId = new Identifier { Name = entityName };

                // Create the request object.
                MDSTestService.BusinessRulesGetRequest ruleGetRequest = new MDSTestService.BusinessRulesGetRequest();
                ruleGetRequest.ResultOptions = new BRResultOptions();
                ruleGetRequest.ResultOptions.BusinessRules = ResultType.Details;
                ruleGetRequest.GetCriteria = new BRGetCriteria();
                ruleGetRequest.GetCriteria.ModelId = modelId;
                ruleGetRequest.GetCriteria.EntityId = entityId;
                ruleGetRequest.GetCriteria.MemberType = BREntityMemberType.Leaf;
                ruleGetRequest.GetCriteria.BusinessRuleIds = new System.Collections.ObjectModel.Collection<Identifier> { };
                ruleGetRequest.GetCriteria.BusinessRuleIds.Add(new Identifier { Name = ruleName });

                // Get the business rules.
                MDSTestService.BusinessRulesGetResponse ruleGetResponse = clientProxy.BusinessRulesGet(ruleGetRequest);
                HandleOperationErrors(ruleGetResponse.OperationResult);

                BusinessRule selectedBusinessRule = ruleGetResponse.BusinessRuleSet.BusinessRulesMember[0];

                // Create the request object.
                MDSTestService.BusinessRulesDeleteRequest ruleDeleteRequest = new MDSTestService.BusinessRulesDeleteRequest();
                ruleDeleteRequest.DeleteCriteria = new BRDeleteCriteria();
                ruleDeleteRequest.DeleteCriteria.BusinessRules = new System.Collections.ObjectModel.Collection<Guid> { };
                ruleDeleteRequest.DeleteCriteria.BusinessRules.Add(selectedBusinessRule.Identifier.Id);

                // Delete the business rule.
                MDSTestService.MessageResponse ruleDeleteResponse = clientProxy.BusinessRulesDelete(ruleDeleteRequest);
                HandleOperationErrors(ruleDeleteResponse.OperationResult);

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

    }
}
