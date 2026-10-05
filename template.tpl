___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "eTLD+1",
  "categories": [
    "UTILITY"
  ],
  "description": "Returns the effective top-level domain + 1 (eTLD+1) of the given domain or URL. The eTLD+1 is typically the highest-level domain on which you can set a cookie.",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "SELECT",
    "name": "url",
    "displayName": "URL Source",
    "macrosInSelect": true,
    "selectItems": [
      {
        "value": "default_url",
        "displayValue": "Page URL / Default"
      }
    ],
    "simpleValueType": true,
    "defaultValue": "default_url",
    "alwaysInSummary": true
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const getUrl = require('getUrl');
const parseUrl = require('parseUrl');
const makeString = require('makeString');

const MULTI_PART_SUFFIXES = {
  // UK
  'ac.uk': true,
  'co.uk': true,
  'gov.uk': true,
  'ltd.uk': true,
  'me.uk': true,
  'net.uk': true,
  'nhs.uk': true,
  'org.uk': true,
  'plc.uk': true,
  'police.uk': true,
  'sch.uk': true,

  // AU
  'asn.au': true,
  'com.au': true,
  'edu.au': true,
  'gov.au': true,
  'id.au': true,
  'net.au': true,
  'org.au': true,

  // NZ
  'ac.nz': true,
  'co.nz': true,
  'cri.nz': true,
  'geek.nz': true,
  'gen.nz': true,
  'govt.nz': true,
  'iwi.nz': true,
  'kiwi.nz': true,
  'maori.nz': true,
  'mil.nz': true,
  'net.nz': true,
  'org.nz': true,
  'school.nz': true,

  // JP
  'ac.jp': true,
  'ad.jp': true,
  'co.jp': true,
  'ed.jp': true,
  'go.jp': true,
  'gr.jp': true,
  'lg.jp': true,
  'ne.jp': true,
  'or.jp': true,

  // BR / MX / AR / TR / IN / ZA (common)
  'com.br': true,
  'net.br': true,
  'org.br': true,
  'gov.br': true,
  'edu.br': true,
  'com.mx': true,
  'org.mx': true,
  'gob.mx': true,
  'edu.mx': true,
  'com.ar': true,
  'net.ar': true,
  'org.ar': true,
  'gob.ar': true,
  'edu.ar': true,
  'com.tr': true,
  'net.tr': true,
  'org.tr': true,
  'gov.tr': true,
  'edu.tr': true,
  'co.in': true,
  'firm.in': true,
  'net.in': true,
  'org.in': true,
  'gen.in': true,
  'ind.in': true,
  'co.za': true,
  'net.za': true,
  'org.za': true,
  'gov.za': true,
  'ac.za': true,

  // US (a few common 3-label public suffixes)
  'k12.ca.us': true,
  'k12.ny.us': true,
  'k12.tx.us': true,
};

const DIGITS = '0123456789';

function str(v) {
  return makeString(v) || '';
}

function lowerTrim(v) {
  return str(v).trim().toLowerCase();
}

function cutAtFirst(s, a, b, c) {
  // Cuts s at the earliest occurrence of any of the separators a/b/c (if present)
  let i = -1;
  let j = s.indexOf(a);
  if (j !== -1) i = j;
  j = s.indexOf(b);
  if (j !== -1 && (i === -1 || j < i)) i = j;
  j = s.indexOf(c);
  if (j !== -1 && (i === -1 || j < i)) i = j;
  return i === -1 ? s : s.substring(0, i);
}

function extractHost(input) {
  const parsed = parseUrl(input);
  let host = parsed && parsed.hostname ? parsed.hostname : '';
  if (!host) {
    let s = str(input);

    // Remove scheme if present (best effort, no regex)
    const schemePos = s.indexOf('://');
    if (schemePos !== -1) s = s.substring(schemePos + 3);
    if (s.substring(0, 2) === '//') s = s.substring(2);

    // Cut off path/query/fragment
    s = cutAtFirst(s, '/', '?', '#');

    host = s;
  }

  host = lowerTrim(host);
  if (!host) return '';

  // Remove userinfo
  const at = host.lastIndexOf('@');
  if (at !== -1) host = host.substring(at + 1);

  // Remove trailing dot
  if (host.substring(host.length - 1) === '.')
    host = host.substring(0, host.length - 1);

  // IPv6 literal like [::1] -> keep, don't try to strip port
  if (host.substring(0, 1) === '[') return host;

  // Strip port if present (best effort; may mis-handle unbracketed IPv6, which we avoid by returning host later)
  const colon = host.lastIndexOf(':');
  if (colon !== -1) host = host.substring(0, colon);

  return host;
}

function parseDec(s) {
  // Returns { ok: boolean, value: number }
  s = str(s);
  if (!s.length) return { ok: false, value: 0 };

  let val = 0;
  let i, ch, d;
  for (i = 0; i < s.length; i++) {
    ch = s.substring(i, i + 1);
    d = DIGITS.indexOf(ch);
    if (d === -1) return { ok: false, value: 0 };
    val = val * 10 + d;
  }
  return { ok: true, value: val };
}

function isIPv4(host) {
  const parts = str(host).split('.');
  if (parts.length !== 4) return false;

  let i, p, n;
  for (i = 0; i < 4; i++) {
    p = parts[i];
    if (!p || p.length > 3) return false;
    if (p.length > 1 && p.substring(0, 1) === '0') return false;

    n = parseDec(p);
    if (!n.ok) return false;
    if (n.value < 0 || n.value > 255) return false;
  }
  return true;
}

function joinLast(parts, n) {
  let start = parts.length - n;
  if (start < 0) start = 0;

  let out = '';
  for (let i = start; i < parts.length; i++) {
    if (out) out += '.';
    out += parts[i];
  }
  return out;
}

function computeEtldPlusOne(host) {
  if (!host) return '';
  if (host === 'localhost') return host;
  if (host.substring(0, 1) === '[') return host; // IPv6 literal
  if (isIPv4(host)) return host;

  // If it contains ':' but isn't bracketed, treat as non-domain (likely IPv6-ish) and return as-is.
  if (host.indexOf(':') !== -1) return host;

  const raw = host.split('.');
  const parts = [];
  let i;
  for (i = 0; i < raw.length; i++) {
    if (raw[i]) parts.push(raw[i]);
  }
  if (parts.length <= 1) return host;

  const s2 = joinLast(parts, 2);
  const s3 = parts.length >= 3 ? joinLast(parts, 3) : '';

  let publicSuffix;
  if (s3 && MULTI_PART_SUFFIXES[s3]) publicSuffix = s3;
  else if (MULTI_PART_SUFFIXES[s2]) publicSuffix = s2;
  else publicSuffix = parts[parts.length - 1];

  const psLen = publicSuffix.split('.').length;
  if (parts.length <= psLen) return host;

  return joinLast(parts, psLen + 1);
}

let input = data.url === 'default_url' ? getUrl('host') : data.url;
if (!input) return undefined;

input = lowerTrim(input);
if (!input) return undefined;

const host = extractHost(input);
if (!host) return undefined;

return computeEtldPlusOne(host);


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "get_url",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urlParts",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "host",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "queriesAllowed",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Basic subdomain
  code: |-
    /***********************
     * Test: Basic subdomain
     ***********************/
    r = runCode({ url: 'https://www.sub.example.com/path?x=1#y' });
    assertThat(r).isEqualTo('example.com');
- name: Multi-part suffix UK
  code: |-
    /****************************
     * Test: Multi-part suffix UK
     ****************************/
    r = runCode({ url: 'https://a.b.example.co.uk/some/page' });
    assertThat(r).isEqualTo('example.co.uk');
- name: Multi-part suffix AU
  code: |-
    /*********************************
     * Test: Multi-part suffix AU
     *********************************/
    r = runCode({ url: 'http://shop.example.com.au/checkout' });
    assertThat(r).isEqualTo('example.com.au');
- name: Protocol-relative URL
  code: |-
    /*******************************
     * Test: Protocol-relative URL
     *******************************/
    r = runCode({ url: '//cdn.assets.example.com/foo' });
    assertThat(r).isEqualTo('example.com');
- name: Raw hostname (no scheme / path)
  code: |-
    /****************************************
     * Test: Raw hostname (no scheme / path)
     ****************************************/
    r = runCode({ url: 'deep.subdomain.example.com' });
    assertThat(r).isEqualTo('example.com');
- name: Userinfo + port + trailing dot
  code: |-
    /***************************************
     * Test: Userinfo + port + trailing dot
     ***************************************/
    r = runCode({ url: 'https://user:pass@sub.example.com:8080/path.' });
    assertThat(r).isEqualTo('example.com');

    r = runCode({ url: 'example.com.' });
    assertThat(r).isEqualTo('example.com');
- name: IPv4 passthrough
  code: |-
    /********************
     * Test: IPv4 passthrough
     ********************/
    r = runCode({ url: 'http://192.168.0.1:8080/admin' });
    assertThat(r).isEqualTo('192.168.0.1');
- name: localhost passthrough
  code: |-
    /********************
     * Test: localhost passthrough
     ********************/
    r = runCode({ url: 'http://localhost:3000/' });
    assertThat(r).isEqualTo('localhost');
- name: Bracketed IPv6 passthrough
  code: |-
    /********************
     * Test: Bracketed IPv6 passthrough
     ********************/
    r = runCode({ url: 'http://[::1]:8080/' });
    assertThat(r).isEqualTo('[::1]');
- name: Non-HTTP scheme (mailto-like)
  code: |-
    /*************************************
     * Test: Non-HTTP scheme (mailto-like)
     *************************************/
    r = runCode({ url: 'mailto:user@example.com' });
    assertThat(r).isEqualTo('example.com');
- name: Empty
  code: |-
    /************************
     * Test: Empty
     ************************/
    r = runCode({ url: '' });
    assertThat(r).isEqualTo(undefined);
- name: Undefined
  code: |-
    /************************
     * Test: undefined
     ************************/
    r = runCode({});
    assertThat(r).isEqualTo(undefined);
- name: default_url
  code: |-
    /************************
     * Test: default_url
     ************************/
    mock('getUrl', 'tagmanager.google.com');
    r = runCode({url: 'default_url'});
    assertThat(r).isEqualTo('google.com');
setup: let r;


___NOTES___

Created on 05/10/2026, 21:32:48
