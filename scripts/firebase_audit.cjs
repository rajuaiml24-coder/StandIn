// Read-only, bounded production audit using the Firebase CLI's authenticated API client.
const { resolve } = require('node:path');
const { mkdirSync, writeFileSync, readFileSync } = require('node:fs');
const cli = process.env.FIREBASE_TOOLS_PATH;
if (!cli) throw new Error('Set FIREBASE_TOOLS_PATH to the installed Firebase CLI directory.');
const { getAllAccounts } = require(resolve(cli, 'lib/auth'));
const { requireAuth } = require(resolve(cli, 'lib/requireAuth'));
const { Client } = require(resolve(cli, 'lib/apiv2'));
const { firestoreOrigin } = require(resolve(cli, 'lib/api'));
const rules = require(resolve(cli, 'lib/gcp/rules'));
const project = 'standin-5755d';
const root = `projects/${project}/databases/(default)`;
const output = resolve('build/firebase-audit');

async function main() {
  const account = getAllAccounts().find(a => a.user.email === 'standin.withwells@gmail.com');
  if (!account) throw new Error('The authorized StandIn account is not signed in.');
  await requireAuth({ project, user: account.user, tokens: account.tokens });
  const client = new Client({ auth: true, apiVersion: 'v1', urlPrefix: firestoreOrigin });
  const name = await rules.getLatestRulesetName(project, 'cloud.firestore');
  const files = name ? await rules.getRulesetContent(name) : [];
  mkdirSync(output, { recursive: true });
  const local = readFileSync(resolve('firestore.rules'), 'utf8').replace(/\r\n/g, '\n');
  const deployed = files.find(file => file.name.endsWith('.rules'))?.content ?? '';
  const verified = deployed.replace(/\r\n/g, '\n') === local;
  if (!process.argv.includes('--verify')) {
    writeFileSync(resolve(output, 'previous-rules.json'), JSON.stringify({ ruleset: name, files }, null, 2));
  }
  const indices = (await client.get(`${root}/collectionGroups/organizations/indexes`)).body.indexes ?? [];
  const indexSummary = indices.map(index => ({ fields: index.fields, state: index.state }));
  const organizations = (await client.get(`${root}/documents/organizations`, {
    queryParams: { pageSize: 100 }
  })).body;
  const configuration = (await client.get(`${root}/documents/configuration`, {
    queryParams: { pageSize: 100 }
  })).body;
  const publishingGate = (configuration.documents ?? []).find(document => document.name.endsWith('/sharedRules'));
  if (!publishingGate && configuration.nextPageToken) throw new Error('Publishing gate could not be verified in the bounded configuration sample.');
  const fullRulePublishingEnabled = publishingGate?.fields?.enabled?.booleanValue === true;
  const docs = organizations.documents ?? [];
  const templates = {};
  for (const document of docs) {
    const id = document.name.split('/').at(-1);
    templates[id] = {};
    for (const collection of ['policies', 'calendars', 'scopes']) {
      const response = (await client.get(`${document.name}/${collection}`, { queryParams: { pageSize: 20 } })).body;
      templates[id][collection] = (response.documents ?? []).map(item => ({
        id: item.name.split('/').at(-1), fields: Object.keys(item.fields ?? {}),
        scopeId: item.fields?.scopeId?.stringValue, parentId: item.fields?.parentId?.stringValue,
        state: item.fields?.state?.stringValue,
        evaluationPeriod: item.fields?.evaluationPeriod?.stringValue,
        basis: item.fields?.basis?.stringValue,
        minimumPercent: item.fields?.minimumPercent?.doubleValue ?? item.fields?.minimumPercent?.integerValue,
        activePolicyId: item.fields?.activePolicyId?.stringValue,
        activeCalendarId: item.fields?.activeCalendarId?.stringValue
      }));
    }
  }
  const summary = {
    project, ruleset: name, deployedRulesMatchLocal: verified,
    fullRulePublishingEnabled,
    organizationSampleSize: docs.length, sampleIsComplete: !organizations.nextPageToken,
    organizations: docs.map(document => ({
      id: document.name.split('/').at(-1), name: document.fields?.name?.stringValue,
      type: document.fields?.type?.stringValue,
      followerCount: Number(document.fields?.followerCount?.integerValue ?? 0),
      hasOwner: Boolean(document.fields?.createdBy?.stringValue),
      hasLowercaseName: Boolean(document.fields?.name_lowercase?.stringValue),
      hasSearchTokens: Boolean(document.fields?.name_tokens?.arrayValue?.values?.length),
      hasPolicyPointer: Boolean(document.fields?.activePolicyId?.stringValue),
      hasCalendarPointer: Boolean(document.fields?.activeCalendarId?.stringValue)
    })),
    indexes: indexSummary, templates
  };
  writeFileSync(resolve(output, 'summary.json'), JSON.stringify(summary, null, 2));
  console.log(JSON.stringify(process.argv.includes('--verify') ? {
    project, ruleset: name, deployedRulesMatchLocal: verified,
    fullRulePublishingEnabled,
    organizationCount: docs.length, indexes: indexSummary.map(index => ({ state: index.state, fields: index.fields }))
  } : summary, null, 2));
  if (process.argv.includes('--verify') && !verified) throw new Error('Deployed rules do not match the tested local rules.');
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
