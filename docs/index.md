﻿---
title: Home
summary: Application and update reports for Windows images built in Azure DevOps using Hashicorp Packer and Evergreen
authors:
    - Aaron Parker
---
# Packer image reports

Reports here are for Windows images built using Hasicorp [Packer](https://www.packer.io/) for Windows Server and Windows 10 images for Windows Virtual Desktop, Citrix Cloud etc., in Azure. Images are built via Azure DevOps and stored in a [Shared Image Library](https://docs.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries).

Leverages [Evergreen](https://stealthpuppy.com/evergreen) to create images with the latest application versions so that each image is always up to date.

Reports are created in markdown format for basic tracking of image updates.

| Operating System | Status |
|:--|:--|
| Windows 10 Enterprise | [![Build Status](https://dev.azure.com/stealthpuppyLab/Packer/_apis/build/status/windows10-enterprise-wvd?branchName=main)](https://dev.azure.com/stealthpuppyLab/Packer/_build/latest?definitionId=2&branchName=main) |
| Windows 10 multi-session | [![Build Status](https://dev.azure.com/stealthpuppyLab/Packer/_apis/build/status/windows10-multisession-wvd?branchName=main)](https://dev.azure.com/stealthpuppyLab/Packer/_build/latest?definitionId=2&branchName=main) |
| Windows 11 Enterprise | [![Build Status](https://dev.azure.com/stealthpuppyLab/Packer/_apis/build/status/windows11-enterprise-wvd?branchName=main)](https://dev.azure.com/stealthpuppyLab/Packer/_build/latest?definitionId=2&branchName=main) |
| Windows 11 multi-session | [![Build Status](https://dev.azure.com/stealthpuppyLab/Packer/_apis/build/status/windows11-multisession-wvd?branchName=main)](https://dev.azure.com/stealthpuppyLab/Packer/_build/latest?definitionId=2&branchName=main) |
| Windows Server 2022 | [![Build Status](https://dev.azure.com/stealthpuppyLab/Packer/_apis/build/status/windowsserver2022-wvd?branchName=main)](https://dev.azure.com/stealthpuppyLab/Packer/_build/latest?definitionId=2&branchName=main) |
| Windows 11 (GitHub Workflow) | [![build-windows11-templates](https://github.com/aaronparker/packer/actions/workflows/windows11-avd.yml/badge.svg)](https://github.com/aaronparker/packer/actions/workflows/windows11-avd.yml) |
