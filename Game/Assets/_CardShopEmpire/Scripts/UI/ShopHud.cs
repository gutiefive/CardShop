using UnityEngine;
using UnityEngine.UI;
namespace CardShopEmpire {
 public sealed class ShopHud : MonoBehaviour {
  public Text Prompt, Crosshair, Notice, ProductText;
  public Button CloseButton, ResumeButton;
  void Awake(){CloseButton.onClick.AddListener(CloseInspection);ResumeButton.onClick.AddListener(Resume);}
  public GameObject Inspection, PausePanel;
  public bool Blocked => Inspection.activeSelf || PausePanel.activeSelf;
  float noticeUntil;
  public void SetFocus(string text){ Prompt.text=text; Crosshair.color=string.IsNullOrEmpty(text)?Color.white:Color.yellow; }
  public void Inspect(ProductDefinition p){
   ProductText.text=$"{p.DisplayName}\n\n{p.Description}\n\nType: {p.Type}\nWholesale: ${p.BasePurchasePrice:0.00}\nRetail: ${p.BaseRetailPrice:0.00}\n\nInspection only · no purchasing or pack opening\nEscape or Close to return";
   Inspection.SetActive(true);
  }
  public void CloseInspection()=>Inspection.SetActive(false);
  public void Resume()=>PausePanel.SetActive(false);
  public void Escape(){if(Inspection.activeSelf) CloseInspection(); else PausePanel.SetActive(!PausePanel.activeSelf);}
  public void Notify(string message){Notice.text=message;noticeUntil=Time.unscaledTime+3;}
  void Update(){if(Time.unscaledTime>noticeUntil) Notice.text="";}
 }
}
