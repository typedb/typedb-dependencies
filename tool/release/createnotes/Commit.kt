/*
 * Copyright (C) 2021 Vaticle
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package com.vaticle.dependencies.tool.release.createnotes

import com.eclipsesource.json.Json
import com.google.api.client.http.GenericUrl
import com.google.api.client.http.HttpHeaders
import com.google.api.client.http.javanet.NetHttpTransport

fun getLastRelease(org: String, repo: String, githubToken: String): Version? {
    val response = NetHttpTransport()
        .createRequestFactory()
        .buildGetRequest(GenericUrl("https://api.github.com/repos/$org/$repo/releases"))
        .setHeaders(HttpHeaders().setAuthorization("Token $githubToken").setAccept("application/vnd.github.v3+json"))
        .execute()
    val body = Json.parse(String(response.content.readBytes()))
    val releases = body.asArray().map { e -> Version.parse(e.asObject().get("tag_name").asString()) }
    return releases.maxOrNull()
}

fun getCommits(org: String, repo: String, from: Version?, to: String, githubToken: String): List<String> {
    val from_ = "d67639340ebf55a76e1f8cbd0fd7194cd212da02" // from?.toString() ?: TODO("get first commit")
    val response = NetHttpTransport()
        .createRequestFactory()
        .buildGetRequest(GenericUrl("https://api.github.com/repos/$org/$repo/compare/$from_...$to"))
        .setHeaders(HttpHeaders().setAuthorization("Token $githubToken").setAccept("application/vnd.github.v3+json"))
        .execute()
    val body = Json.parse(String(response.content.readBytes()))
    return body.asObject().get("commits").asArray().map { e -> e.asObject().get("sha").asString() }
}