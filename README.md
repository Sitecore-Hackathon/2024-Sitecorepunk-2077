# Hackathon Submission Entry form

- [Hackathon Submission Entry form](#hackathon-submission-entry-form)
  - [🥇 Team name](#-team-name)
  - [📂 Category](#-category)
  - [📜 Description](#-description)
    - [🔊 SPE Text-to-Speech Audio Synthesis Module](#-spe-text-to-speech-audio-synthesis-module)
      - [🌟 Features](#-features)
  - [📹 Video link](#-video-link)
  - [✅ Prerequisites and Dependencies](#-prerequisites-and-dependencies)
    - [⚙ Azure Service Provisioning](#-azure-service-provisioning)
      - [🧠 Azure Cognitive Services Speech Service](#-azure-cognitive-services-speech-service)
      - [📦 Azure Storage Account](#-azure-storage-account)
  - [👩‍🏫 Installation instructions](#-installation-instructions)
    - [⚙ API Configuration](#-api-configuration)
  - [🚀 Usage instructions](#-usage-instructions)
  - [📝 Comments](#-comments)

<br/>

## 🥇 Team name
- Sitecorepunk 2077 
  - [@GabeStreza](https://www.twitter.com/GabeStreza)

![](/docs/images/sitecorepunk2077.png)

## 📂 Category
- Best Module for XM/XP or XM Cloud

## 📜 Description

In today's digital era, captivating your audience with compelling content is paramount. Content Authors and Marketers are not only tasked with crafting impactful messages but also with ensuring these messages are **universally accessible** and resonate deeply with their audience. 

Audio content goes beyond the usual ways of reading and visual barriers, delivering an experience accessible without the need to use your hands or eyes, effectively serving a wide range of user needs and lifestyles.

From individuals with visual impairments, to busy professionals seeking to consume information on the go, or those who simply prefer auditory learning, **audio content opens up a world of possibilities**. 

It embodies the essence of convenience and inclusively, allowing content to be more dynamically integrated into the daily lives of people everywhere.

---

*""Audio articles help me get the news easier and faster. I have dyslexia, which makes it hard to read the news. Screen-reading software is unreliable, and I don't always have access to it." — [Troy Phillips](https://beyondwords.io/knowledge-base/why-people-listen-audio-content/)"*

---

By Leveraging the capabilities of **Microsoft Azure AI Speech** to provided an audio alternative directly to users without the need for them to install special software, the **SPE Text-to-Speech Audio Synthesis Module** module significantly enhances **content accessibility**, catering to diverse user preferences and needs.

<br/>

### 🔊 SPE Text-to-Speech Audio Synthesis Module

> ![](/docs/images/1.png)
> ![](/docs/images/2.png)

#### 🌟 Features
   - Converts text content into lifelike speech, allowing Content Authors to provide an audio version of their content directly within Sitecore.

   - Utilizes the [Microsoft Azure Cognitive Services Speech Service](https://azure.microsoft.com/en-us/services/cognitive-services/speech-services/) to dynamically generate audio from selected text fields. Whether it's a blog post, news article, or product description, every piece of content gains the potential to reach a wider audience, including those with visual impairments or those who simply prefer audio formats.

   - Leverages [Azure Blob Storage ](https://azure.microsoft.com/en-us/products/storage/blobs/) to store generated audio files.  Once an audio file is uploaded to the dedicated `Azure Storage` container, a link will be populated on the context page item's `Audio URL` field.

   - The process is streamlined with a custom `Ribbon Button` on the `Home` tab , which triggers a user-friendly and interactive `Sitecore PowerShell Extensions` dialog.  The user can configure options for voice selection, field selection, and speech rate adjustment, ensuring that the audio output matches the intended tone and speech rate.

   - The module supports multiple languages.  For demo purposes (and due to natural time constraints that come with this event) the implementation supports the following languages:
     - `English (en)`
     - `Japanese (ja-JP)`
     - `German (de-DE)`
     - `Danish (da)`

   - A series of Neural (life-like, natural-sounding voices) [Microsoft Azure Cognitive Services Speech Service](https://azure.microsoft.com/en-us/services/cognitive-services/speech-services/) voice options have been hand-selected and configured for each supported language in this implementation. 

---


## 📹 Video link

- [Watch the demonstration video here](https://youtu.be/dHBVjJ3TV-8)

---

## ✅ Prerequisites and Dependencies

- Clean Sitecore XP/XM or XM Cloud instance with `Sitecore PowerShell Extensions` installed (no SXA)
  - Built on `10.3.1` but should work in lower versions just fine. 
- An active Azure subscription with access to the following Resources:
  - `Azure Cognitive Services Speech Service`
  - `Azure Storage Account`
- API Keys for `Azure Cognitive Services Speech Service` and `Azure Storage Account` must be configured within the Sitecore item at `/sitecore/system/Modules/PowerShell/Script Library/Sitecorepunk2077/API Settings`.

---

### ⚙ Azure Service Provisioning

> 🚨 The Sitecore package provided provided already contains the appropriate keys for judges to test.  I intend to keep both `Azure AI Speech` and `Azure Storage` resources active for at least 30 days.
> 
#### 🧠 Azure Cognitive Services Speech Service

  > ![](/docs/images/3.png)

#### 📦 Azure Storage Account

  > ![](/docs/images/4.png)

  > ![](/docs/images/5.png)

  > ![](/docs/images/6.png)

---

## 👩‍🏫 Installation instructions

1. Install the `\src\Sitecorepunk2077_TextToSpeech.zip` Sitecore package using the `Sitecore Installation Wizard`.
   - When prompted to overwrite, select `Yes to all` for files and `Overwrite` > `Apply to all` for items.

<br/>

2. From the `Sitecore Desktop`, click the `Start Menu`, then click the `PowerShell Toolbox`, and select `Rebuild script integration points`

    > ![](/docs/images/7.png)

<br/>


3. Open the `Content Editor`, select the root `sitecore` item, select `Publish Item`.  
   - Republish
   - Publish subitems
   - Select all all languages

    > ![](/docs/images/8.png)

    > ![](/docs/images/9.png)

<br/>


1. Open the instance in a browser: `https://{YOURINSTANCE}cm.dev.local/?sc_lang=en`
    The page title should say `Sitecore announces 2024 Most Valuable Professionals`
   > ![](/docs/images/10.png)

<br/>

5. Confirm that the `API Settings` item has the `Azure Cognitive Services Speech Service` and `Azure Storage` account and key details filled out.

<br/>

### ⚙ API Configuration

> 🚨 The Sitecore package provided already contains the appropriate keys for judges to test.  I intend to keep both `Azure AI Speech` and `Azure Storage` resources active for at least 30 days.

1. Navigate to `/sitecore/system/Modules/PowerShell/Script Library/Sitecorepunk2077/API Settings`.
   - ID: `{D51D7222-0F22-4D20-911C-F0D1A677440C}`

2. Fill in the following fields with your Azure service details:
   - **Azure AI Services Configuration**
     - `Azure AI Services Key`
       - `Azure AI services` > `Keys and Endpoints` > `'KEY 1'` or `'KEY 2'`
     - `Azure AI Endpoint Region`
       - `Azure AI services` > `Keys and Endpoints` > `Location/Region` (e.g. '`centralus`')
   - **Azure Storage Configuration**
     - `Storage Account Name`
       - `Azure Storage` > `Access Keys` > `Storage account name`
     - `Storage Key`
       - `Azure Storage` > `Access Keys` > `Key`
     - `Storage Container Name`
       - `Azure Storage` > `Containers` > `Name` (e.g. '`audiostorage`')

> > ![](/docs/images/11.png)

---


## 🚀 Usage instructions

1. Select an item that inherits from the `/sitecore/templates/Feature/Sitecorepunk2077/Text to Speech` template.  For the demo, the `Home` item template (inherits the `Text to Speech` template. is pre-configured with the corresponding `AudioPlayback` `Controller rendering`.

2. Whith the `/sitecore/content/Home` item selected, click on the `Generate Audio` button in the `Ribbon` under the `Home` tab.

3. In the dialog, configure the following options:
   - **Field to convert to speech:** Select the field whose content you wish to convert.
     - For the demo, the `Sample Item` is used. 
   - **Include Title?:** Choose whether to include the item's title in the audio.
   - **Voice:** Select a voice that matches the item's context language.
   - **Speech Rate:** Optionally adjust the speech rate (0.5 for slow to 2.0 for fast; default is 1.0).

4. Click "`Continue`" to generate and upload the audio file. The `Audio URL` field of the item will be updated with the link to the audio file.

5. After saving and publishing the home item, note that the `Generate Audio` button under the `Home` tab now say `Regenerate Audio`.  
   - Removing the value from the `Audio URL` button will result in the button saying `Generate Audio`.

6. Navigate to the Home page and observe an **audio player** that's sticky to the bottom right-hand corner of the page. 

7. Press play to confirm audio plays as expected. 

8. Return to the `/sitecore/content` item.  Try re-generating the audio for the the same English version but using a different Voice selection.  Save and publish after processing and note difference in audio when returning the to the `Home` page.  

---

## 📝 Comments

This module was developed as part of the Sitecore Hackathon 2024 by Team Sitecorepunk 2077.


The raw PowerShell file defined in the `Sitecorepunk 2077` PowerShell Module can be reviewed here:
-  `\src\_Sitecorepunk2077-TextToSpeech.ps1`

   > ![](/docs/images/12.png)
