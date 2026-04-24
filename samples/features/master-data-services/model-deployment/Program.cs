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
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using Microsoft.MasterDataServices.Deployment;
using Microsoft.MasterDataServices.Services.DataContracts;

namespace ModelDUtil
{
    /// <summary>
    /// Sample Model Deployment utility.
    /// </summary>
    class ModelDUtil
    {
        #region Console app methods
        /// <summary>
        /// Entry point for the console app.
        /// </summary>
        /// <param name="args">Array of command line arguments</param>
        static void Main(string[] args)
        {
            /// <summary>
            /// Used for input or output package file name parameters.
            /// </summary>
            string packageFile = string.Empty;

            /// <summary>
            /// Used for model name parameter.
            /// </summary>
            string modelName = string.Empty;

            /// <summary>
            /// Used for version name parameter.
            /// </summary>
            string versionName = string.Empty;

            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            try
            {
                // Parse the command line options.
                Modes mode = ModelDUtil.ParseCommandLine(args, out packageFile, out modelName, out versionName);
                switch (mode)
                {
                    case Modes.CreatePackage:
                        ModelDUtil.CreatePackage(packageFile, modelName, versionName);
                        break;

                    case Modes.DeployClone:
                        ModelDUtil.DeployClone(packageFile);
                        break;

                    case Modes.DeployNew:
                        ModelDUtil.DeployNew(packageFile, modelName);
                        break;

                    case Modes.DeployUpdate:
                        ModelDUtil.DeployUpdate(packageFile, versionName);
                        break;

                    case Modes.ListModels:
                        ModelDUtil.ListModels();
                        break;

                    case Modes.ListVersions:
                        ModelDUtil.ListVersions(modelName);
                        break;

                    default:
                        ModelDUtil.DisplayHelp();
                        break;
                }

                stopwatch.Stop();
                Console.WriteLine(string.Empty);
                Console.WriteLine("Operation completed successfully. Elapsed time: {0}", stopwatch.Elapsed.ToString("c", CultureInfo.CurrentCulture));
            }
            catch (Exception e)
            {
                stopwatch.Stop();
                Console.WriteLine(string.Empty);
                Console.WriteLine("Operation aborted. Elapsed time: {0}", stopwatch.Elapsed.ToString("c", CultureInfo.CurrentCulture));
                Console.WriteLine("Exception: ");
                Console.WriteLine(e);
            }


            Console.WriteLine(string.Empty);
            Console.WriteLine("Press Enter to continue...");
            Console.ReadLine();
        }

        /// <summary>
        /// Parse string args provided on the command line.
        /// </summary>
        /// <param name="args">Array of string arguments.</param>
        /// <returns>True if command line arguments were successfully parsed, false otherwise.</returns>
        private static Modes ParseCommandLine(string[] args, out string packageFile, out string modelName, out string versionName)
        {
            packageFile = string.Empty;
            modelName = string.Empty;
            versionName = string.Empty;

            // The first argument must be a switch specifying the mode
            Modes mode = Modes.Help;
            int countArgs = args.Length;

            if (countArgs > 0)
            {
                try
                {
                    mode = (Modes)Enum.Parse(typeof(Modes), args[0], true);
                }
                catch (ArgumentException)
                {
                    // Invalid mode argument. Display help.
                    return Modes.Help;
                }

                // Now check for additional parameters, as appropriate for the given mode.
                switch (mode)
                {
                    case Modes.CreatePackage:
                        // Package name, Model name, and Version name expected.
                        if (countArgs != 4)
                        {
                            return Modes.Help;
                        }
                        packageFile = args[1];
                        modelName = args[2];
                        versionName = args[3];
                        break;

                    case Modes.DeployClone:
                        // Package file name expected.
                        if (countArgs != 2)
                        {
                            return Modes.Help;
                        }
                        packageFile = args[1];
                        break;

                    case Modes.DeployNew:
                        // Package name and Model name expected.
                        if (countArgs != 3)
                        {
                            return Modes.Help;
                        }
                        packageFile = args[1];
                        modelName = args[2];
                        break;

                    case Modes.DeployUpdate:
                        // Package name and Version name expected.
                        if (countArgs != 3)
                        {
                            return Modes.Help;
                        }
                        packageFile = args[1];
                        versionName = args[2];
                        break;

                    case Modes.ListModels:
                        // No additional params expected.
                        if (countArgs != 1)
                        {
                            return Modes.Help;
                        }
                        break;

                    case Modes.ListVersions:
                        // Model name expected.
                        if (countArgs != 2)
                        {
                            return Modes.Help;
                        }
                        modelName = args[1];
                        break;

                    case Modes.Help:
                        // No additional params expected.
                        if (countArgs != 1)
                        {
                            return Modes.Help;
                        }
                        break;

                    default:
                        // Unknown enum value.
                        return Modes.Help;
                }
            }

            return mode;
        }

        /// <summary>
        /// Displays help on how to use this console app.
        /// </summary>
        private static void DisplayHelp()
        {
            Console.WriteLine("Usage:");
            Console.WriteLine("    ModelDUtil <mode> [params]");
            Console.WriteLine(string.Empty);
            Console.WriteLine("where <mode> is one of the following:");
            Console.WriteLine(string.Empty);
            Console.WriteLine("ListModels -- returns a list of all the user models in the target system");
            Console.WriteLine("    ModelDUtil ListModels");
            Console.WriteLine(string.Empty);
            Console.WriteLine("ListVersions -- returns a list of the versions for a given model");
            Console.WriteLine("    ModelDUtil ListVersions <model name>");
            Console.WriteLine(string.Empty);
            Console.WriteLine("CreatePackage -- create a package file for a given model, including a specific version of master data");
            Console.WriteLine("    ModelDUtil CreatePackage <output package file name> <model name> <version name>");
            Console.WriteLine(string.Empty);
            Console.WriteLine("DeployClone -- deploys a clone of a model from a given package");
            Console.WriteLine("    ModelDUtil DeployClone <input package file name>");
            Console.WriteLine(string.Empty);
            Console.WriteLine("DeployNew -- deploys a model from a given package with the new given name");
            Console.WriteLine("    ModelDUtil DeployNew <input package file name> <new model name>");
            Console.WriteLine(string.Empty);
            Console.WriteLine("DeployUpdate -- deploys an update to a given version of a model from a given package");
            Console.WriteLine("    ModelDUtil DeployUpdate <input package file name> <version name to update>");
            Console.WriteLine(string.Empty);
            Console.WriteLine("Help -- displays this help");
            Console.WriteLine("    ModelDUtil Help");
            Console.WriteLine(string.Empty);
            Console.WriteLine(string.Empty);
            Console.WriteLine("Note: names that contain spaces should be wrapped with double quotation marks. For Example:");
            Console.WriteLine("    ModelDUtil DeployUpdate mypackage.pkg \"Version 1\"");
        }
        #endregion Console app methods

        #region Model Deployment Sample methods

        /// <summary>
        /// Creates a model deployment package file for a specified model.
        /// </summary>
        /// <param name="packageFile">File name for the output package.</param>
        /// <param name="modelName">Name of the model to export to package.</param>
        /// <param name="versionName">Name of the version of master data to include in the package.</param>
        private static void CreatePackage(string packageFile, string modelName, string versionName)
        {
            Console.WriteLine("Creating a package for model {0}", modelName);
            ModelReader reader = new ModelReader();

            // Set the model ID on the reader to the passed-in model name.
            Identifier modelId = new Identifier();
            modelId.Name = modelName;
            reader.ModelId = modelId;

            // Set the version ID on the reader to the passed-in version name.
            Identifier versionId = new Identifier();
            versionId.Name = versionName;
            reader.VersionId = versionId;

            // Create a package that contains metadata, business rules, and master data.
            List<Package> packages = reader.CreatePackage(true).ToList();

            // Save the package
            Console.WriteLine("Saving package to file {0}", packageFile);
            using (var stream = new FileStream(packageFile, FileMode.CreateNew))
            {
                var firstPackage = packages.FirstOrDefault();
                if (firstPackage != null)
                    firstPackage.Serialize(stream);
            }
        }

        /// <summary>
        /// Deploys a clone of a model from a specified package.
        /// </summary>
        /// <param name="packageFile">File name of the input package.</param>
        private static void DeployClone(string packageFile)
        {
            Console.WriteLine("Deploying clone of package {0}", packageFile);
            ModelDeployer deployer = new ModelDeployer();

            // Deploy the package.

            Warnings errorsAsWarnings = null;
            using (var package = new PackageReader(packageFile))
            {
                Identifier newModelId = null;
                errorsAsWarnings = deployer.DeployClone(package.GetEnumerator(), out newModelId);
            }

            Console.WriteLine("Package was deployed with {0} warnings", errorsAsWarnings.Count);
        }

        /// <summary>
        /// Deploys a copy of a model from a package, with a new name.
        /// </summary>
        /// <param name="packageFile">File name of the input package.</param>
        /// <param name="modelName">New name for the model being deployed.</param>
        private static void DeployNew(string packageFile, string modelName)
        {
            Console.WriteLine("Deploying package {0} using new model name {1}", packageFile, modelName);
            ModelDeployer deployer = new ModelDeployer();

            // Deploy the package.
            Warnings errorsAsWarnings = null;
            using (var package = new PackageReader(packageFile))
            {
                Identifier newId = null;
                errorsAsWarnings = deployer.DeployNew(package.GetEnumerator(), modelName, out newId);
            }

            Console.WriteLine("Package was deployed with {0} warnings", errorsAsWarnings.Count);
        }

        /// <summary>
        /// Deploys an update to an existing model from a specified package.
        /// </summary>
        /// <param name="packageFile">File name of the input package.</param>
        /// <param name="versionName">Name of the version of master data to update.</param>
        private static void DeployUpdate(string packageFile, string versionName)
        {
            Console.WriteLine("Deploying package {0}, updating version {1} of the master data", packageFile, versionName);
            ModelDeployer deployer = new ModelDeployer();
            ModelReader reader = new ModelReader();


            // Deploy it.
            Warnings errorsAsWarnings = null;
            using (var package = new PackageReader(packageFile))
            {
                // Get the ID for the model named in the package
                var firstPackage = package.FirstOrDefault();
                if (firstPackage != null)
                {
                    Identifier modelId = GetModelIdentifier(reader, firstPackage.ModelId.Name);

                    // Now get the version Id for that model and the given version name.
                    reader.ModelId = modelId;
                }
                Identifier versionId = GetVersionIdentifier(reader, versionName);

                errorsAsWarnings = deployer.DeployUpdate(package.GetEnumerator(), true, versionId);
            }

            Console.WriteLine("Package was deployed with {0} warnings", errorsAsWarnings.Count);
        }

        /// <summary>
        /// Displays a list of the models in the system.
        /// </summary>
        private static void ListModels()
        {
            Console.WriteLine("Models:");
            ModelReader reader = new ModelReader();

            Collection<Identifier> models = reader.GetModels();
            foreach (Identifier modelId in models)
            {
                Console.WriteLine(modelId.Name);
            }
        }

        /// <summary>
        /// Displays a list of the versions for a given model in the system.
        /// </summary>
        /// <param name="modelName">Name of model for which to list versions.</param>
        private static void ListVersions(string modelName)
        {
            Console.WriteLine("Versions for model {0}:", modelName);
            ModelReader reader = new ModelReader();

            // Set the model ID on the reader to the passed-in model name.
            Identifier modelId = new Identifier();
            modelId.Name = modelName;
            reader.ModelId = modelId;

            // Get the versions (all status types) for the specified model.
            Collection<Identifier> versions = reader.GetVersions(VersionStatusFlags.All);
            foreach (Identifier versionId in versions)
            {
                Console.WriteLine(versionId.Name);
            }
        }

        #endregion Model Deployment Sample methods

        #region Reader helpers
        /// <summary>
        /// Get the Identifier object for the model with the given name.
        /// </summary>
        /// <param name="reader">The <see cref="ModelReader"/> to use to retrieve the model information.</param>
        /// <param name="modelName">Name of model to look for</param>
        /// <returns>The identifier if it exists, otherwise an empty Identifier</returns>
        public static Identifier GetModelIdentifier(ModelReader reader, string modelName)
        {
            Identifier modelId = new Identifier();
            Collection<Identifier> modelIdentifiers;
            modelIdentifiers = reader.GetModels();
            foreach (Identifier id in modelIdentifiers)
            {
                if (id.Name.Equals(modelName))
                {
                    modelId = id;
                    break;
                }
            }

            return modelId;
        }

        /// <summary>
        /// Get the Identifier object for the version with the given name.
        /// NOTE: ModelId property must be set on the reader first
        /// </summary>
        /// <param name="reader">The model reader object to use for the request.</param>
        /// <param name="versionName">Name of version to look for,</param>
        /// <returns>The identifier if it exists, otherwise an empty Identifier</returns>
        public static Identifier GetVersionIdentifier(ModelReader reader, string versionName)
        {
            Identifier versionId = new Identifier();
            Collection<Identifier> versionIdentifiers;
            versionIdentifiers = reader.GetVersions(VersionStatusFlags.All);
            foreach (Identifier id in versionIdentifiers)
            {
                if (id.Name.Equals(versionName, StringComparison.OrdinalIgnoreCase))
                {
                    versionId = id;
                    break;
                }
            }

            return versionId;
        }
        #endregion Reader helpers
    }
}
