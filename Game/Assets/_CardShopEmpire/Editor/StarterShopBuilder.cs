using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem.UI;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
namespace CardShopEmpire.Editor {
 public static class StarterShopBuilder {
  public const string ScenePath="Assets/_CardShopEmpire/Scenes/StarterShop.unity";
  const string Root="Assets/_CardShopEmpire/";
  static Material wood, wall, blue, red, glass;
  [MenuItem("Card Shop Empire/Generate Starter Shop")]
  public static void Generate(){
   if(!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;
   Build();
  }
  // Batch entry point: -executeMethod CardShopEmpire.Editor.StarterShopBuilder.Build
  public static void Build(){
   Directory.CreateDirectory(Root+"Scenes");Directory.CreateDirectory(Root+"Data");Directory.CreateDirectory(Root+"Materials");AssetDatabase.Refresh();
   Configure();
   wood=Mat("WarmWood",new Color(.46f,.27f,.13f)); wall=Mat("Cream",new Color(.86f,.8f,.63f));
   blue=Mat("RookieBlue",new Color(.08f,.35f,.7f));red=Mat("RookieRed",new Color(.8f,.17f,.1f));
   glass=Mat("GlassStyle",new Color(.4f,.75f,.85f)); // Opaque pale blue placeholder, no transparency sorting dependency.
   var pack=Product("rookie-series-pack","Rookie Series Booster Pack","A sealed pack of fictional neighborhood baseball prospects.",2,4,ProductType.BoosterPack);
   var box=Product("rookie-series-box","Rookie Series Hobby Box","A hobby box of Rookie Series baseball packs.",40,65,ProductType.HobbyBox);
   var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);
   var root=new GameObject("Starter Shop").transform;
   Cube(root,"Floor",new Vector3(0,-.15f,0),new Vector3(12,.3f,14),wood);
   Cube(root,"Ceiling",new Vector3(0,4.2f,0),new Vector3(12,.2f,14),wall);
   Cube(root,"Back wall",new Vector3(0,2,7),new Vector3(12,4,.2f),wall);
   foreach(int side in new[]{-1,1}) Cube(root,"Side wall",new Vector3(side*6,2,0),new Vector3(.2f,4,14),wall);
   foreach(int side in new[]{-1,1}) Cube(root,"Entrance wall",new Vector3(side*3.6f,2,-7),new Vector3(4.8f,4,.2f),wall);
   Cube(root,"Entrance lintel",new Vector3(0,3.6f,-7),new Vector3(2.4f,1.2f,.2f),blue);
   // Enclosed porch keeps the player inside the prototype without a locked doorway.
   Cube(root,"Porch floor",new Vector3(0,-.15f,-8),new Vector3(2.4f,.3f,2),wood);
   Cube(root,"Porch back",new Vector3(0,1.5f,-9),new Vector3(2.4f,3,.2f),glass);
   foreach(int side in new[]{-1,1}) Cube(root,"Porch side",new Vector3(side*1.2f,1.5f,-8),new Vector3(.2f,3,2),wall);
   Cube(root,"Checkout counter",new Vector3(3, .6f,3.5f),new Vector3(4,1.2f,1),wood);
   var sign=Cube(root,"Shop sign",new Vector3(1.5f,1.65f,3.5f),new Vector3(.65f,.55f,.12f),red);sign.AddComponent<ShopSign>();
   for(int i=0;i<3;i++){
    float x=-4+i*4;
    Cube(root,"Shelf backing",new Vector3(x,1.4f,5.8f),new Vector3(2.5f,2.8f,.2f),wood);
    foreach(int side in new[]{-1,1}) Cube(root,"Shelf upright",new Vector3(x+side*1.2f,1.4f,5.4f),new Vector3(.15f,2.8f,.9f),wood);
    for(int level=0;level<3;level++){
     float y=.35f+level*.8f;
     Cube(root,"Shelf",new Vector3(x,y,5.4f),new Vector3(2.5f,.12f,1),wood);
     for(int k=0;k<3;k++) Sample(root, k%2==0?pack:box,new Vector3(x+(k-1)*.65f,y+.28f,5.25f));
    }
   }
   Cube(root,"Display base",new Vector3(-3,.45f,0),new Vector3(3,.9f,1.3f),wood);
   Cube(root,"Glass style display top",new Vector3(-3,.95f,0),new Vector3(3,.1f,1.3f),glass);
   Sample(root,pack,new Vector3(-3,1.2f,-.2f));Sample(root,box,new Vector3(-2.2f,1.25f,-.2f));
   for(int i=0;i<3;i++){
    var lamp=new GameObject("Overhead light");lamp.transform.SetParent(root);lamp.transform.position=new Vector3((i-1)*4,3.7f,0);
    var light=lamp.AddComponent<Light>();light.type=LightType.Point;light.range=12;light.intensity=3;light.color=new Color(1,.9f,.72f);
   }
   RenderSettings.ambientLight=new Color(.5f,.48f,.42f);
   var sun=new GameObject("Soft fill").AddComponent<Light>();sun.transform.SetParent(root);sun.type=LightType.Directional;sun.intensity=.65f;sun.transform.rotation=Quaternion.Euler(45,-25,0);
   var hud=Hud(root);
   var player=new GameObject("Player spawn");player.transform.SetParent(root);player.transform.position=new Vector3(0,.1f,-4);
   var cc=player.AddComponent<CharacterController>();cc.height=1.8f;cc.radius=.3f;cc.center=new Vector3(0,.9f,0);cc.stepOffset=.3f;
   var camera=new GameObject("Player camera").AddComponent<Camera>();camera.transform.SetParent(player.transform,false);camera.transform.localPosition=new Vector3(0,1.65f,0);camera.nearClipPlane=.05f;camera.tag="MainCamera";camera.AddComponent<AudioListener>();camera.GetUniversalAdditionalCameraData();
   var controller=player.AddComponent<FirstPersonController>();controller.View=camera;controller.Hud=hud;
   var ray=player.AddComponent<InteractionRaycaster>();ray.View=camera;ray.Hud=hud;
   // The ray starts within the character capsule; exclude the player's layer explicitly.
   player.layer=2;ray.Mask=~(1<<2);
   var events=new GameObject("UI events",typeof(EventSystem),typeof(InputSystemUIInputModule));events.transform.SetParent(root);events.GetComponent<InputSystemUIInputModule>().AssignDefaultActions();
   EditorSceneManager.SaveScene(scene,ScenePath);
   EditorBuildSettings.scenes=new[]{new EditorBuildSettingsScene(ScenePath,true)};
   AssetDatabase.SaveAssets();
   Validate();
  }
  static void Configure(){
   var settings=new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset")[0]);
   var input=settings.FindProperty("activeInputHandler");if(input!=null){input.intValue=1;settings.ApplyModifiedPropertiesWithoutUndo();}
   var pipeline=AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(Root+"Data/ShopPipeline.asset");
   if(!pipeline){
    var renderer=ScriptableObject.CreateInstance<UniversalRendererData>();AssetDatabase.CreateAsset(renderer,Root+"Data/ShopRenderer.asset");
    pipeline=UniversalRenderPipelineAsset.Create(renderer);AssetDatabase.CreateAsset(pipeline,Root+"Data/ShopPipeline.asset");
   }
   GraphicsSettings.defaultRenderPipeline=pipeline;QualitySettings.renderPipeline=pipeline;
   PlayerSettings.productName="Card Shop Empire";PlayerSettings.companyName="Card Shop Empire";
   PlayerSettings.defaultScreenWidth=1280;PlayerSettings.defaultScreenHeight=720;
  }
  static Material Mat(string name,Color color){
   string path=Root+"Materials/"+name+".mat";var m=AssetDatabase.LoadAssetAtPath<Material>(path);
   if(!m){m=new Material(Shader.Find("Universal Render Pipeline/Lit"));AssetDatabase.CreateAsset(m,path);}m.color=color;EditorUtility.SetDirty(m);return m;
  }
  static ProductDefinition Product(string id,string name,string description,float cost,float retail,ProductType type){
   string path=Root+"Data/"+id+".asset";var p=AssetDatabase.LoadAssetAtPath<ProductDefinition>(path);
   if(!p){p=ScriptableObject.CreateInstance<ProductDefinition>();AssetDatabase.CreateAsset(p,path);}p.Initialize(id,name,description,cost,retail,type);EditorUtility.SetDirty(p);return p;
  }
  static GameObject Cube(Transform parent,string name,Vector3 position,Vector3 scale,Material material){
   var go=GameObject.CreatePrimitive(PrimitiveType.Cube);go.name=name;go.transform.SetParent(parent);go.transform.position=position;go.transform.localScale=scale;go.GetComponent<Renderer>().sharedMaterial=material;return go;
  }
  static void Sample(Transform root,ProductDefinition p,Vector3 position){
   var go=Cube(root,p.DisplayName,position,p.Type==ProductType.BoosterPack?new Vector3(.3f,.4f,.08f):new Vector3(.45f,.4f,.4f),p.Type==ProductType.BoosterPack?blue:red);
   go.AddComponent<ProductInteractable>().Product=p;
  }
  static RectTransform Rect(Transform parent,string name,Vector2 anchor,Vector2 position,Vector2 size){
   var go=new GameObject(name,typeof(RectTransform));var rect=go.GetComponent<RectTransform>();rect.SetParent(parent,false);rect.anchorMin=rect.anchorMax=anchor;rect.anchoredPosition=position;rect.sizeDelta=size;return rect;
  }
  static Text Label(Transform parent,string text,Vector2 anchor,Vector2 position,Vector2 size,int fontSize=22){
   var rect=Rect(parent,"Label",anchor,position,size);var label=rect.gameObject.AddComponent<Text>();label.font=Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");label.text=text;label.fontSize=fontSize;label.color=Color.white;label.alignment=TextAnchor.MiddleCenter;label.raycastTarget=false;return label;
  }
  static GameObject Panel(Transform parent,string name){
   var rect=Rect(parent,name,new Vector2(.5f,.5f),Vector2.zero,new Vector2(680,420));rect.gameObject.AddComponent<Image>().color=new Color(.06f,.09f,.13f,.98f);return rect.gameObject;
  }
  static void Button(Transform parent,string text,Vector2 position){
   var rect=Rect(parent,text,new Vector2(.5f,.5f),position,new Vector2(220,50));rect.gameObject.AddComponent<Image>().color=new Color(.16f,.35f,.55f);rect.gameObject.AddComponent<UnityEngine.UI.Button>();
   // Runtime listeners are not serialized: HUD wires button actions in Awake instead.
   Label(rect,text,new Vector2(.5f,.5f),Vector2.zero,new Vector2(220,50));
  }
  static ShopHud Hud(Transform root){
   var go=new GameObject("HUD",typeof(Canvas),typeof(CanvasScaler),typeof(GraphicRaycaster),typeof(ShopHud));go.transform.SetParent(root);go.GetComponent<Canvas>().renderMode=RenderMode.ScreenSpaceOverlay;
   var scaler=go.GetComponent<CanvasScaler>();scaler.uiScaleMode=CanvasScaler.ScaleMode.ScaleWithScreenSize;scaler.referenceResolution=new Vector2(1280,720);
   var h=go.GetComponent<ShopHud>();
   h.Crosshair=Label(go.transform,"+",new Vector2(.5f,.5f),Vector2.zero,new Vector2(40,40));
   h.Prompt=Label(go.transform,"",new Vector2(.5f,0),new Vector2(0,90),new Vector2(900,50));
   Label(go.transform,"Cash: $500.00 (placeholder)",new Vector2(0,1),new Vector2(210,-35),new Vector2(400,50));
   Label(go.transform,"WASD · Move   Shift · Sprint   E · Interact   Esc · Menu",new Vector2(.5f,0),new Vector2(0,25),new Vector2(1100,40),18);
   h.Notice=Label(go.transform,"",new Vector2(.5f,1),new Vector2(0,-75),new Vector2(900,50));
   h.Inspection=Panel(go.transform,"Product inspection");h.ProductText=Label(h.Inspection.transform,"",new Vector2(.5f,.5f),new Vector2(0,25),new Vector2(620,300));
   Button(h.Inspection.transform,"Close",new Vector2(0,-165));h.CloseButton=h.Inspection.GetComponentInChildren<UnityEngine.UI.Button>();h.Inspection.SetActive(false);
   h.PausePanel=Panel(go.transform,"Pause menu");Label(h.PausePanel.transform,"PAUSED",new Vector2(.5f,.5f),new Vector2(0,80),new Vector2(500,80),32);
   Button(h.PausePanel.transform,"Resume",new Vector2(0,-40));h.ResumeButton=h.PausePanel.GetComponentInChildren<UnityEngine.UI.Button>();h.PausePanel.SetActive(false);return h;
  }
  [MenuItem("Card Shop Empire/Validate Starter Shop")]
  public static void Validate(){
   var players=Object.FindObjectsByType<FirstPersonController>(FindObjectsSortMode.None);
   if(players.Length!=1 || !players[0].View || !players[0].Hud || !players[0].GetComponent<CharacterController>()) throw new System.InvalidOperationException("Invalid player setup");
   var rays=Object.FindObjectsByType<InteractionRaycaster>(FindObjectsSortMode.None);
   if(rays.Length!=1 || !rays[0].View || !rays[0].Hud || rays[0].Range<=0) throw new System.InvalidOperationException("Invalid interaction setup");
   var hud=players[0].Hud;
   if(!hud.Prompt || !hud.Crosshair || !hud.ProductText || !hud.Inspection || !hud.PausePanel || !hud.CloseButton || !hud.ResumeButton) throw new System.InvalidOperationException("Missing HUD references");
   if(!GraphicsSettings.defaultRenderPipeline) throw new System.InvalidOperationException("Missing URP pipeline");
   var ids=new System.Collections.Generic.HashSet<string>();
   foreach(string guid in AssetDatabase.FindAssets("t:ProductDefinition",new[]{Root+"Data"})){
    var p=AssetDatabase.LoadAssetAtPath<ProductDefinition>(AssetDatabase.GUIDToAssetPath(guid));
    if(!p.IsValid || !ids.Add(p.StableId)) throw new System.InvalidOperationException("Invalid or duplicate product ID");
   }
   if(ids.Count!=2) throw new System.InvalidOperationException("Expected two product definitions");
   foreach(var p in Object.FindObjectsByType<ProductInteractable>(FindObjectsSortMode.None)) if(!p.Product || !p.GetComponent<Collider>()) throw new System.InvalidOperationException("Invalid product object");
   Debug.Log("Starter shop reference validation passed");
  }
 }
}
