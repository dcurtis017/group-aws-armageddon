# Lab 2A

```bash
curl -k -I https://armageddon-lab1-alb-1041566435.us-east-1.elb.amazonaws.com
HTTP/2 403
server: awselb/2.0
date: Tue, 13 Jan 2026 23:15:24 GMT
content-type: text/plain; charset=utf-8
content-length: 9

curl -I https://app.spicychipfans.click
HTTP/2 200
content-type: text/html; charset=utf-8
content-length: 93
date: Tue, 13 Jan 2026 23:16:27 GMT
server: Werkzeug/3.1.5 Python/3.9.23
x-cache: Miss from cloudfront
via: 1.1 46c3e5d262356b9fe7f87fe739392632.cloudfront.net (CloudFront)
x-amz-cf-pop: ATL59-P18
x-amz-cf-id: Cl5bSGfHdyChzGyOvNRbEbyilZMIK29Wq7hYMTg_evjsB86M3scmOw==

curl -I https://spicychipfans.click
HTTP/2 200
content-type: text/html; charset=utf-8
content-length: 93
date: Tue, 13 Jan 2026 23:16:49 GMT
server: Werkzeug/3.1.5 Python/3.9.23
x-cache: Miss from cloudfront
via: 1.1 1ca022f41313316c410ac09d970dc626.cloudfront.net (CloudFront)
x-amz-cf-pop: ATL59-P18
x-amz-cf-id: 5a6WTZYWlQPxD5jNgFWXGN5w-3Hl3SfXCtH54lv7Wv6Mkr2i4BCipA==

aws wafv2 list-web-acls --scope CLOUDFRONT
{
    "NextMarker": "armageddon-lab1-waf",
    "WebACLs": [
        {
            "Name": "CreatedByCloudFront-6f0c3450",
            "Id": "d865a0cd-672e-4cda-b542-d8c549367efc",
            "Description": "",
            "LockToken": "36b7b8e6-e112-4835-a4f2-ee2ec90bf813",
            "ARN": "arn:aws:wafv2:us-east-1:264799070891:global/webacl/CreatedByCloudFront-6f0c3450/d865a0cd-672e-4cda-b542-d8c549367efc"
        },
        {
            "Name": "CreatedByCloudFront-79f3f9c1",
            "Id": "f73b1f76-fbf1-4df6-b303-dbc27de4cfd6",
            "Description": "",
            "LockToken": "836acba2-de22-4ce0-8bf6-b5a659fc89e3",
            "ARN": "arn:aws:wafv2:us-east-1:264799070891:global/webacl/CreatedByCloudFront-79f3f9c1/f73b1f76-fbf1-4df6-b303-dbc27de4cfd6"
        },
        {
            "Name": "armageddon-lab1-waf",
            "Id": "56e3b1ea-b972-451a-93e2-f06199842742",
            "Description": "",
            "LockToken": "e2eeda7c-634f-410f-bcc1-95399f1db08c",
            "ARN": "arn:aws:wafv2:us-east-1:264799070891:global/webacl/armageddon-lab1-waf/56e3b1ea-b972-451a-93e2-f06199842742"
        }
    ]
}

aws cloudfront get-distribution --id "E2O5GIAW5QULEF" --query "Distribution.DistributionConfig.WebACLId"
"arn:aws:wafv2:us-east-1:264799070891:global/webacl/armageddon-lab1-waf/56e3b1ea-b972-451a-93e2-f06199842742"

dig app.spicychipfans.click A +short
54.230.79.41
54.230.79.53
54.230.79.20
54.230.79.23


dig spicychipfans.click A +short
54.230.79.41
54.230.79.53
54.230.79.20
54.230.79.23
```

# Deliverable B

### Correctness Proof (CLI evidence)

```bash
curl -i https://spicychipfans.click/static/example.txt
HTTP/2 200
content-type: text/plain; charset=utf-8
content-length: 37
server: Werkzeug/3.1.5 Python/3.9.23
content-disposition: inline; filename=example.txt
last-modified: Mon, 19 Jan 2026 21:20:11 GMT
date: Mon, 19 Jan 2026 22:15:24 GMT
cache-control: public, max-age=8600, immutable
expires: Tue, 20 Jan 2026 00:38:44 GMT
etag: "1768857611.9827313-37-2962164636"
x-cache: Hit from cloudfront
via: 1.1 7ffc445380e9de8b1b68e19c51af3ef2.cloudfront.net (CloudFront)
x-amz-cf-pop: ATL59-P11
x-amz-cf-id: UDf_DoYBvA5qubZR98GoKhPddaMdPQnjGI1QBjUnJj7X3oTSXrEf4Q==
age: 692

This is a test of the blah blah blah

curl -i https://spicychipfans.click/api/list
HTTP/2 200
content-type: text/html; charset=utf-8
content-length: 77
date: Mon, 19 Jan 2026 22:28:09 GMT
server: Werkzeug/3.1.5 Python/3.9.23
x-cache: Miss from cloudfront
via: 1.1 cef0837120f79784412d36f7eaef85a0.cloudfront.net (CloudFront)
x-amz-cf-pop: ATL59-P11
x-amz-cf-id: sQYe_7b3-BWItY8mvTz1eLr-SZEm03juZ2JbVJKesZcQklwYD6ZpiA==
<h3>Notes</h3><ul><li>3: hello3</li><li>2: hello2</li><li>1: hello1</li></ul>%

curl -i https://spicychipfans.click/api/list
HTTP/2 200
content-type: text/html; charset=utf-8
content-length: 77
date: Mon, 19 Jan 2026 22:29:09 GMT
server: Werkzeug/3.1.5 Python/3.9.23
x-cache: Miss from cloudfront
via: 1.1 cef0837120f79784412d36f7eaef85a0.cloudfront.net (CloudFront)
x-amz-cf-pop: ATL59-P11
x-amz-cf-id: 5Ny2uipFnChH2K7txxIVkzPMS4B1dwWGftRFBIKJgRtPsJWHdXUtXg==

<h3>Notes</h3><ul><li>3: hello3</li><li>2: hello2</li><li>1: hello1</li></ul>%
```

B) A short written explanation:
“What is my cache key for /api/\* and why?”
<span style="color:#2BA9E5;font-weight:bold;">spicychipfans.click/api/list. Because our cache policy says to not include headers, cookies or query strings cloudfront will only use the domain name and url path.</span>
“What am I forwarding to origin and why?”
<span style="color:#2BA9E5;font-weight:bold;">For api routes we're forwarding all cookies, headers and query strings. We do this because api routes may depend on querty string data to return the correct response. The api may also rely on cookie or header information to determine the user making the request.</span>

## Deliverable C - Haiku

チューバッカには毛皮がある。
その毛皮はとてもふわふわだ。
今すぐその毛皮を撫でなければならない。

## Deliverable D

```bash
# Static Content Caching
curl -i https://spicychipfans.click/static/example.txt
HTTP/2 200
content-type: text/plain; charset=utf-8
content-length: 37
server: Werkzeug/3.1.5 Python/3.9.23
content-disposition: inline; filename=example.txt
last-modified: Mon, 19 Jan 2026 21:20:11 GMT
date: Mon, 19 Jan 2026 22:15:24 GMT
cache-control: public, max-age=8600, immutable
expires: Tue, 20 Jan 2026 00:38:44 GMT
etag: "1768857611.9827313-37-2962164636"
x-cache: Hit from cloudfront
via: 1.1 041c3cee23e607cab16217b2da9c09ca.cloudfront.net (CloudFront)
x-amz-cf-pop: ATL59-P11
x-amz-cf-id: MpGS3ARTuqvSHyMpNmpJRbbF81aRlAepgc8Y4vaU1UYu1TMH3O2Mow==
age: 1513

This is a test of the blah blah blah

curl -i https://spicychipfans.click/static/example.txt
HTTP/2 200
content-type: text/plain; charset=utf-8
content-length: 37
server: Werkzeug/3.1.5 Python/3.9.23
content-disposition: inline; filename=example.txt
last-modified: Mon, 19 Jan 2026 21:20:11 GMT
date: Mon, 19 Jan 2026 22:15:24 GMT
cache-control: public, max-age=8600, immutable
expires: Tue, 20 Jan 2026 00:38:44 GMT
etag: "1768857611.9827313-37-2962164636"
x-cache: Hit from cloudfront
via: 1.1 abf4ae50a2ae1ac82fffb3fdd5cd5df4.cloudfront.net (CloudFront)
x-amz-cf-pop: ATL59-P11
x-amz-cf-id: PsDXUTPQ3H92oCPF_tqyj5HwqHkhJqs_m3a-FnH3zD6OwjcNDmO-fA==
age: 1516

This is a test of the blah blah blah

# API must not cache unsafe output
curl -i https://spicychipfans.click/api/list
HTTP/2 200
content-type: text/html; charset=utf-8
content-length: 77
date: Mon, 19 Jan 2026 22:28:09 GMT
server: Werkzeug/3.1.5 Python/3.9.23
x-cache: Miss from cloudfront
via: 1.1 cef0837120f79784412d36f7eaef85a0.cloudfront.net (CloudFront)
x-amz-cf-pop: ATL59-P11
x-amz-cf-id: sQYe_7b3-BWItY8mvTz1eLr-SZEm03juZ2JbVJKesZcQklwYD6ZpiA==
<h3>Notes</h3><ul><li>3: hello3</li><li>2: hello2</li><li>1: hello1</li></ul>%

curl -i https://spicychipfans.click/api/list
HTTP/2 200
content-type: text/html; charset=utf-8
content-length: 77
date: Mon, 19 Jan 2026 22:29:09 GMT
server: Werkzeug/3.1.5 Python/3.9.23
x-cache: Miss from cloudfront
via: 1.1 cef0837120f79784412d36f7eaef85a0.cloudfront.net (CloudFront)
x-amz-cf-pop: ATL59-P11
x-amz-cf-id: 5Ny2uipFnChH2K7txxIVkzPMS4B1dwWGftRFBIKJgRtPsJWHdXUtXg==

<h3>Notes</h3><ul><li>3: hello3</li><li>2: hello2</li><li>1: hello1</li></ul>%

# Cache key santity checks (query strings)
curl -i https://spicychipfans.click/static/example.txt\?v\=1
HTTP/2 200
content-type: text/plain; charset=utf-8
content-length: 37
server: Werkzeug/3.1.5 Python/3.9.23
content-disposition: inline; filename=example.txt
last-modified: Mon, 19 Jan 2026 21:20:11 GMT
date: Mon, 19 Jan 2026 22:15:24 GMT
cache-control: public, max-age=8600, immutable
expires: Tue, 20 Jan 2026 00:38:44 GMT
etag: "1768857611.9827313-37-2962164636"
x-cache: Hit from cloudfront
via: 1.1 7ffc445380e9de8b1b68e19c51af3ef2.cloudfront.net (CloudFront)
x-amz-cf-pop: ATL59-P11
x-amz-cf-id: j7qA4BhekCXO4e4AYPjcM7C4UQUMFygGJcn1lYoLmzJPvnSUTYAONg==
age: 1882

This is a test of the blah blah blah

curl -i https://spicychipfans.click/static/example.txt\?v\=1
HTTP/2 200
content-type: text/plain; charset=utf-8
content-length: 37
server: Werkzeug/3.1.5 Python/3.9.23
content-disposition: inline; filename=example.txt
last-modified: Mon, 19 Jan 2026 21:20:11 GMT
date: Mon, 19 Jan 2026 22:15:24 GMT
cache-control: public, max-age=8600, immutable
expires: Tue, 20 Jan 2026 00:38:44 GMT
etag: "1768857611.9827313-37-2962164636"
x-cache: Hit from cloudfront
via: 1.1 abb5a776baf5933de1a6dffce38ed2d6.cloudfront.net (CloudFront)
x-amz-cf-pop: ATL59-P11
x-amz-cf-id: vZ597i-mTW-xOC9DgMrjmiiZOUPTIOdWbXVWzBsvjCJFZIf1X-0lFw==
age: 1886

This is a test of the blah blah blah

# Stale read after write” safety test
curl -i https://spicychipfans.click/api/add\?note\=hello4
HTTP/2 200
content-type: text/html; charset=utf-8
content-length: 21
date: Mon, 19 Jan 2026 22:49:54 GMT
server: Werkzeug/3.1.5 Python/3.9.23
x-cache: Miss from cloudfront
via: 1.1 d675e555cbf6e2393719f46f6cf76774.cloudfront.net (CloudFront)
x-amz-cf-pop: ATL59-P11
x-amz-cf-id: EkFmWKq7nUdB7TImBPjNuQMHS3D3gPrA9VFYgTmiw6jgIDB-e68HUQ==

Inserted note: hello4%

curl -i https://spicychipfans.click/api/list
HTTP/2 200
content-type: text/html; charset=utf-8
content-length: 95
date: Mon, 19 Jan 2026 22:50:02 GMT
server: Werkzeug/3.1.5 Python/3.9.23
x-cache: Miss from cloudfront
via: 1.1 69ee488ca4778da0014795863c48db54.cloudfront.net (CloudFront)
x-amz-cf-pop: ATL59-P11
x-amz-cf-id: u3RuOsO-DqTsxtClmsCa8MSlMB1hAYIwR0kxQeOegtdCIwZKbGrO5g==

<h3>Notes</h3><ul><li>4: hello4</li><li>3: hello3</li><li>2: hello2</li><li>1: hello1</li></ul>%
```
