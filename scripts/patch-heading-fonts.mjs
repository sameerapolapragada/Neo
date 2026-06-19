import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');

const HEADING_KEYS = new Set([
  'title',
  'subtitle',
  'headline',
  'headlineBold',
  'headlineRegular',
  'sectionTitle',
  'sectionLabel',
  'chartTitle',
  'emptyTitle',
  'headerTitle',
  'modalTitle',
  'eyebrow',
  'flowTitle',
  'rowTitle',
  'promptTitle',
  'milestoneTitle',
  'pickerTitle',
  'rowSubtitle',
  'wordmark',
  'wordmarkOnboarding',
  'onboardingTagline',
  'taglineScriptPurple',
  'taglineScriptBlack',
  'name',
  'score',
  'weight',
  'value',
  'quickStatValue',
  'activityValue',
  'promptButtonText',
  'currentValue',
  'periodLabel',
  'insightTitle',
  'featureTitle',
  'cardTitle',
  'footerText',
  'week',
  'streak',
  'progressScore',
  'cardSubtitle',
]);

const WEIGHT_MAP = {
  "'400'": "'400'",
  "'500'": "'600'",
  "'600'": "'600'",
  "'700'": "'700'",
  "'800'": "'800'",
};

function walk(dir, files = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith('.') || entry.name === 'node_modules') continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, files);
    else if (/\.tsx$/.test(entry.name)) files.push(full);
  }
  return files;
}

function ensureImport(source) {
  if (source.includes("from '@/constants/fonts'")) return source;

  const importLine = "import { withAppFont } from '@/constants/fonts';\n";
  const reactNativeMatch = source.match(/^import .+ from 'react-native';\n/m);
  if (reactNativeMatch) {
    const idx = reactNativeMatch.index + reactNativeMatch[0].length;
    return `${source.slice(0, idx)}${importLine}${source.slice(idx)}`;
  }

  const firstImport = source.match(/^import .+\n/m);
  if (firstImport) {
    const idx = firstImport.index + firstImport[0].length;
    return `${source.slice(0, idx)}${importLine}${source.slice(idx)}`;
  }

  return `${importLine}${source}`;
}

function patchStyleBlock(block, key) {
  if (!HEADING_KEYS.has(key)) return block;
  if (block.includes('withAppFont(')) return block;

  let next = block;
  for (const [weight, mapped] of Object.entries(WEIGHT_MAP)) {
    const pattern = new RegExp(`\\n(\\s*)fontWeight: ${weight},\\n`, 'g');
    next = next.replace(pattern, `\n$1...withAppFont(${mapped}),\n`);
  }

  return next;
}

function patchFile(filePath) {
  let source = fs.readFileSync(filePath, 'utf8');
  const original = source;

  source = source.replace(
    /(\n\s*)([A-Za-z0-9_]+):\s*\{([\s\S]*?\n\s*)\},/g,
    (match, indent, key, body) => {
      const patchedBody = patchStyleBlock(body, key);
      if (patchedBody === body) return match;
      return `${indent}${key}: {${patchedBody}},`;
    },
  );

  if (source === original) return false;

  source = ensureImport(source);
  fs.writeFileSync(filePath, source);
  return true;
}

const targets = [
  ...walk(path.join(ROOT, 'components')),
  ...walk(path.join(ROOT, 'app')),
];

const updated = targets.filter(patchFile);
console.log(`Updated ${updated.length} files`);
for (const file of updated) {
  console.log(`- ${path.relative(ROOT, file)}`);
}
