// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

import { CfnCondition, CfnResource, Resource } from "aws-cdk-lib";
const { execSync } = require('child_process');
import path = require("path");

interface CfnNagSuppressRule {
  id: string;
  reason: string;
}

/**
 * Adds CFN NAG suppress rules to the CDK resource.
 * @param resource The CDK resource.
 * @param rules The CFN NAG suppress rules.
 */
export function addCfnSuppressRules(resource: Resource | CfnResource | undefined, rules: CfnNagSuppressRule[]) {
  if (typeof resource === "undefined") return;

  if (resource instanceof Resource) {
    resource = resource.node.defaultChild as CfnResource;
  }

  if (resource.cfnOptions.metadata?.cfn_nag?.rules_to_suppress) {
    resource.cfnOptions.metadata.cfn_nag.rules_to_suppress.push(...rules);
  } else {
    resource.addMetadata("cfn_nag", { rules_to_suppress: rules });
  }
}

/**
 * Adds CDK condition to the CDK resource.
 * @param resource The CDK resource.
 * @param condition The CDK condition.
 */
export function addCfnCondition(resource: Resource | CfnResource | undefined, condition: CfnCondition) {
  if (typeof resource === "undefined") return;

  if (resource instanceof Resource) {
    resource = resource.node.defaultChild as CfnResource;
  }

  resource.cfnOptions.condition = condition;
}

/**
 * Run a shell command from typescript
 * @param shellCommand Command to run in the shell
 * @param pathToRunCommandIn CWD of shell command
 */
export function RunShellCommand(shellCommand: string, pathToRunCommandIn: string) {
  execSync(shellCommand, {
    cwd: pathToRunCommandIn
  });
}

/**
 * Install dependencies of cdk project. This will include the dependencies of the
 * lambda functions which must be installed before esbuild is used to create
 * the bundled assets by cdk synth.
 */
export function InstallDependencies() { 
  const projectCdkSourcePath = path.join(__dirname, `../`);
  RunShellCommand("npm run clean:install", projectCdkSourcePath);
}