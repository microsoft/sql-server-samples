//==============================================================================
//
//    Copyright (c) Microsoft. All rights reserved.
//    This code is licensed under the Microsoft Public License.
//    THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
//    ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
//    IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
//    PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
//
//==============================================================================

using System;
using System.Collections.Generic;
using System.Xml;
using Microsoft.MasterDataServices.WorkflowTypeExtender;
using Microsoft.SharePoint;
using Microsoft.SharePoint.Workflow;

namespace Microsoft.MasterDataServices.SharePointWorkflow
{
    /// <summary>
    /// A sample class that demonstrates how to implement a workflow type extender
    /// for SharePoint workflows. Once built, the assembly that contains this class should be put in the
    /// same folder as the workflow listener (Microsoft.MasterDataServices.Workflow.exe), and the
    /// listener's config file should be updated to reference this class, like this:
    /// <code>
    ///     <setting name="WorkflowTypeExtenders" serializeAs="String">
    ///         <value>SPWF=Microsoft.MasterDataServices.SharePointWorkflow.SharePointWorkflowExtender, Microsoft.MasterDataServices.SharePointWorkflow, Version=1.0.0.0</value>
    ///     </setting>
    /// </code>
    /// </summary>
    public class SharePointWorkflowExtender : IWorkflowTypeExtender
    {
        #region Fields

        /// <summary>
        /// Workflow type name for SharePoint workflows.
        /// </summary>
        private const string WorkflowTypeSharePoint = "SPWF";

        /// <summary>
        /// A cache of SharePoint sites.
        ///    Key = serverUrl
        ///    Value = SharePoint site
        /// </summary>
        private Dictionary<string, SPSite> Sites = new Dictionary<string, SPSite>();

        #endregion Fields

        #region Constructor

        /// <summary>
        /// Constructor.
        /// </summary>
        public SharePointWorkflowExtender()
        {
        }

        #endregion Constructor

        #region IWorkflowTypeExtender Members

        /// <summary>
        /// Starts a workflow of the given type, if it is a SharePoint workflow.
        /// </summary>
        /// <param name="workflowType">The workflow type. The method does nothing if it is not a SharePoint workflow.</param>
        /// <param name="dataElement">The data passed to the workflow.</param>
        public void StartWorkflow(string workflowType, XmlElement dataElement)
        {
            // Ignore non-SharePoint workflows.
            if (string.Equals(workflowType, SharePointWorkflowExtender.WorkflowTypeSharePoint, StringComparison.OrdinalIgnoreCase))
            {
                string serverUrl = dataElement["Server_URL"].InnerText;
                string workflowName = dataElement["Action_ID"].InnerText;

                // Look for the site in the cache.
                SPSite site = null;
                if (!this.Sites.TryGetValue(serverUrl, out site))
                {
                    // Site not in cache, so add it.
                    site = new SPSite(serverUrl);
                    this.Sites[serverUrl] = site;
                }

                // Start the specified workflow.
                SPWeb web = site.OpenWeb();
                web.WorkflowAssociations.UpdateAssociationsToLatestVersion();
                foreach (SPWorkflowAssociation association in web.WorkflowAssociations)
                {
                    if (association.Name == workflowName && association.AllowManual)
                    {
                        site.WorkflowManager.StartWorkflow(null, association, dataElement.OuterXml, SPWorkflowRunOptions.Synchronous);
                        break;
                    }
                }
            }
        }

        #endregion

    }
}
