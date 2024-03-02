using Sitecore.Globalization;
using Sitecorepunk2077.Models;
using System.Web.Mvc;

namespace Sitecorepunk2077.Controllers
{
    public class AudioPlaybackController : Controller
    {
        // GET: Index
        public ActionResult Index()
        {
            // Dictionary item for 'Listen to this content' text
            string TitleText = Translate.TextByLanguage("ListenToThisContent", Sitecore.Context.Language);
            if (string.IsNullOrEmpty(TitleText))
            { TitleText = "Listen to this content"; }

            // Instance of the AudioPlayback model to pass to the view
            // Title text for the title of the component
            // Audio URL for the audio player
            var audioPlaybackIndex = new AudioPlayback()
            {
                TitleText = Translate.TextByLanguage("ListenToThisContent", Sitecore.Context.Language),
                AudioUrl = Sitecore.Context.Item.Fields["Audio URL"]?.Value
            };

            return PartialView("AudioPlayback", audioPlaybackIndex);
        }
    }
}