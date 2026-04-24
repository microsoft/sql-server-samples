
using System.IO;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Azure.WebJobs.Host;
using Newtonsoft.Json;
using Microsoft.Azure.Services.AppAuthentication;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using System;
using ManagedInstanceAutomation.Core;
using ManagedInstanceAutomation.Shared;
using System.Linq;

namespace ManagedInstanceAutomation
{
    public static class AssignDirectoryReadersRoleFunction
    {
        [FunctionName("AssignDirectoryReadersRoleFunction")]
        public static async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "post", Route = null)]HttpRequest req, ILogger log)
        {
            try
            {
                var id = await GetManagedInstanceIdAsync(req);

                var managedInstance = await GetManagedInstanceAsync(id).ConfigureAwait(false);

                var tenantId = managedInstance?.Identity?.TenantId;
                var principalId = managedInstance?.Identity?.PrincipalId;

                if (string.IsNullOrEmpty(tenantId))
                    throw new Exception($"[MSI Not Assigned]: '{managedInstance.Id}'");

                var directoryReadersRole = await GetAzureADDirectoryRoleAsync(tenantId, "Directory Readers");

                return (await AddMemberToAzureADRole(tenantId, directoryReadersRole.ObjectId, principalId).ConfigureAwait(false)) ?
                    (IActionResult)new NoContentResult() : (IActionResult)new BadRequestResult();
            }
            catch(Exception xcp)
            {
                return new BadRequestObjectResult(xcp.Message);
            }
        }

        private class AssignDirectoryReadersRoleFunctionRequest
        {
            public string Id { get; set; }
        }

        private async static Task<string> GetManagedInstanceIdAsync(HttpRequest req)
        {
            var parameters = await FunctionUtils.ParseRequestAsync<AssignDirectoryReadersRoleFunctionRequest>(req);

            if (string.IsNullOrEmpty(parameters.Id))
                throw new Exception(@"Please pass Managed Instance 'id' in the request body.");

            return parameters.Id;
        }

        private async static Task<ManagedInstance> GetManagedInstanceAsync(string id)
        {
            var azureClient = new AzureClient();

            return await azureClient.GetManagedInstanceAsync(id).ConfigureAwait(false);
        }

        private async static Task<DirectoryRole> GetAzureADDirectoryRoleAsync(string tenantId, string displayName)
        {
            var azureClient = new AzureClient();

            var roles = await azureClient.GetAzureADRolesAsync(tenantId).ConfigureAwait(false);

            var directoryReadersRole = roles.Value.FirstOrDefault(r => r.DisplayName == displayName);

            if (directoryReadersRole == null)
            {
                var roleTemplates = await azureClient.GetAzureADRoleTemplatesAsync(tenantId).ConfigureAwait(false);

                var directoryReaderRoleTemplate = roleTemplates.Value.FirstOrDefault(r => r.displayName == displayName);

                directoryReadersRole = await azureClient.EnableAzureADRoleAsync(tenantId, directoryReaderRoleTemplate.objectId).ConfigureAwait(false);
            }
            return directoryReadersRole;
        }

        private async static Task<bool> AddMemberToAzureADRole(string tenantId, string roleId, string memberId)
        {
            var azureClient = new AzureClient();
            var users = await azureClient.GetAzureADDirectoryRoleMembersAsync(tenantId, roleId).ConfigureAwait(false);

            if (!users.Value.Any(u => u.ObjectId == memberId))
            {
                return await azureClient.AddAzureADDirectoryRoleMembersAsync(tenantId, roleId, memberId).ConfigureAwait(false);
            }

            return true;
        }
    }
}
