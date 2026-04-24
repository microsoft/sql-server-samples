# Master Data Services Security API Sample

A sample class that demonstrates how to implement a workflow type extender for SharePoint workflows. Once built, the assembly that contains this class should be put in the same folder as the workflow listener (Microsoft.MasterDataServices.Workflow.exe), and the
listener's config file should be updated to reference this class, like this:

```XML
<code>
    <setting name="WorkflowTypeExtenders" serializeAs="String">
        <value>SPWF=Microsoft.MasterDataServices.SharePointWorkflow.SharePointWorkflowExtender, Microsoft.MasterDataServices.SharePointWorkflow, Version=1.0.0.0</value>
    </setting>
</code>
```