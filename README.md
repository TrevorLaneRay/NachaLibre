<a id="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/TrevorLaneRay/NachaLibre">
    <img src="ScriptIcons/SourceImages/ScriptIcon.png" alt="Logo" width="128" height="128">
  </a>

<h3 align="center">NachaLibre</h3>

  <p align="center">
    An amateur's in-house solution to payroll processing.
    <br />
    <a href="https://github.com/TrevorLaneRay/NachaLibre/tree/main/Documentation"><strong>Explore the docs »</strong></a>
    <br />
    <a href="https://github.com/TrevorLaneRay/NachaLibre/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    &middot;
    <a href="https://github.com/TrevorLaneRay/NachaLibre/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>


<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>


<!-- ABOUT THE PROJECT -->
## About The Project
Lots of people to pay, and repeatedly spending time on it was a pain.  
Had a big spreadsheet of people, their bank accounts, and amounts to pay.  
Needed some way to push payments to many employees in bulk.  
...This is the result.

[![NachaLibre Screen Shot][product-screenshot]](NachaOutput/20260212000934NachaFile.ach)
<p align="right">(<a href="#readme-top">back to top</a>)</p>


### Tools used during development
* [![VSCode][VSCode]][VSCode-url]
* [AutoHotkey v2.0](https://www.autohotkey.com/)
* [Microsoft Excel](https://excel.cloud.microsoft/)
* [Notepad++](https://notepad-plus-plus.org/)
* No AI 😉
<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- GETTING STARTED -->
## Getting Started
I'm assuming you've got your payroll laid out in a spreadsheet, in Microsoft Excel, Apple Numbers, LibreOffice Calc, or Google Docs.  
This is great for running preliminary calculations. Just export it as CSV when ready.  
(See the example spreadsheet and CSV in the [SourceCSVs folder](SourceCSVs) for reference.)

As for the script, you'll want some code editor to tweak it to your taste.  
Personally, I've been using Visual Studio Code lately, but I initially used SciTE4AutoHotkey.  
Notepad++ is a rock-solid editor too, but not as much integration.

To actually run the script, there's two ways to go about it.  
You can run the script directly from source using the AutoHotkey v2.0 runtime.  
Or you can use the compiled version (I've included an executable of it for convenience).  
If you've installed AutoHotkey v2.0, it comes with Ahk2Exe, which can compile your script.

## Prerequisites / Recommendations
### Pick an editor for changing the script:
* VS Code (What I've personally been using as of late.)
  ```sh
  https://www.autohotkey.com/
  ```
* SciTE4AHK (The original editor for AutoHotkey scripts)
  ```sh
  https://www.autohotkey.com/scite4ahk/
  ```
* Notepad++ (A bit less integrated, but a solid editor.)
  ```sh
  https://notepad-plus-plus.org/
  ```

### To run script source code directly or compile to .exe:
* AutoHotkey v2.0
  ```sh
  https://www.autohotkey.com/
  ```

### Installation
1. Take a deep breath. Get relaxed.
2. Download and install AHK.
3. Set your editor to be the default for .ahk source files.
4. Download the git repo to somewhere easy to use. (Your desktop maybe?)
5. Modify the settings .ini file to specify your source CSV, bank info, and payday / transaction date offsets.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- USAGE CLARIFICATION -->
## Usage
1. Have a read through the documentation folder. (Some useful info in there.)
2. Play around with the example files (See SourceCSV.csv and OriginalSettingsFile.ini).
3. Make sure to keep backups of previous versions of files. (Can't tell you how many times this saved me.)
4. Launch the script, or your compiled version.
5. Use the hotkeys to trigger the functions.
    * F11: Run the script on the specified CSV, outputting an .ach file that can be uploaded to your bank.
    * F10: Open the script's settings file. (Reload the script after saving to apply any changes.)
    * Shift+F12: Reload the script (handy if you've made a change to the Settings .ini file).
    * Ctrl+Shift+F12: Terminate the script. (Can also be closed through the tray icon's context menu.)

_For some fun reading, please refer to the [Documentation](Documentation)._

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- ROADMAP -->
## Roadmap
- [⏳] Automatically split .ach if it exceeds bank's daily limit.
- [⏳] Replace hotkey triggers with GUI buttons.
- [⏳] Add GUI for changing settings like file/date/bank info.
    - [🤔] Figure out some way to identify and warn about bank holidays.

See the [open issues](https://github.com/TrevorLaneRay/NachaLibre/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- CONTRIBUTING -->
## Contributing
Contributions of ideas would be **greatly appreciated**.  
I'm just doing this as a side project, so if you want to reproduce this as your own, I've licensed it so you can do so without worries. 😘  
If you've got a suggestion that would make this better, please fork the repo and create a pull request.  
You can also simply open an issue with the tag "enhancement".

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/CheeseDip`)
3. Commit your Changes (`git commit -m 'Add some cheese.'`)
4. Push to the Branch (`git push origin feature/CheeseDip`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Top contributors:

<a href="https://github.com/TrevorLaneRay/NachaLibre/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=TrevorLaneRay/NachaLibre" alt="contrib.rocks image" />
</a>


<!-- LICENSE -->
## License
Distributed under CC0 1.0 Universal. See [LICENSE.txt](LICENSE.txt) for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- CONTACT -->
## Contact
Trevor Ray - [@TrevorLaneRay](https://x.com/TrevorLaneRay) - trevorlaneray@gmail.com

Project Link: [https://github.com/TrevorLaneRay/NachaLibre](https://github.com/TrevorLaneRay/NachaLibre)

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- ACKNOWLEDGMENTS -->
## Acknowledgments
* [NACHA](https://www.nacha.org/) - The people behind the ACH network.
* [Treasury Software](https://www.treasurysoftware.com/) - The inspiration for this project.
* [Intuit Quickbooks](https://quickbooks.intuit.com/ca/pricing/) - The motivation to avoid proprietary software and predatory vendor lock-in.
* [GroggyOtter](https://github.com/GroggyOtter/ahkv2_definition_rewrite) - Made my life so much better with AHK integration for VSCode.
* [othneildrew](https://github.com/othneildrew/Best-README-Template) - Definitely made creating this ReadMe easier.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/TrevorLaneRay/NachaLibre.svg?style=for-the-badge
[contributors-url]: https://github.com/TrevorLaneRay/NachaLibre/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/TrevorLaneRay/NachaLibre.svg?style=for-the-badge
[forks-url]: https://github.com/TrevorLaneRay/NachaLibre/network/members
[stars-shield]: https://img.shields.io/github/stars/TrevorLaneRay/NachaLibre.svg?style=for-the-badge
[stars-url]: https://github.com/TrevorLaneRay/NachaLibre/stargazers
[issues-shield]: https://img.shields.io/github/issues/TrevorLaneRay/NachaLibre.svg?style=for-the-badge
[issues-url]: https://github.com/TrevorLaneRay/NachaLibre/issues
[license-shield]: https://img.shields.io/github/license/TrevorLaneRay/NachaLibre.svg?style=for-the-badge
[license-url]: https://github.com/TrevorLaneRay/NachaLibre/blob/main/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/trevorlaneray
[product-screenshot]: Documentation/ExampleOutputScreenshot.png
<!-- Shields.io badges. -->
[VSCode]: https://custom-icon-badges.demolab.com/badge/Visual%20Studio%20Code-0078d7.svg?logo=vsc&logoColor=white
[VSCode-url]: https://code.visualstudio.com/