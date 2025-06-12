// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

use std::env;

fn main() -> std::io::Result<()> {
    let protos_raw = env::var("PROTOS").expect("PROTOS environment variable is not set");
    let protos: Vec<&str> = protos_raw.split(";").filter(|&str| !str.is_empty()).collect();

    tonic_build::configure()
        .server_mod_attribute(".", "#[allow(non_camel_case_types)]")
        .client_mod_attribute(".", "#[allow(non_camel_case_types)]")
        .compile_protos(&protos, &[
            env::var("PROTOS_ROOT").expect("PROTOS_ROOT environment variable is not set")
        ])
}
