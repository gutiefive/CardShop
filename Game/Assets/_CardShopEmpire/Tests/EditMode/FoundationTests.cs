using System;
using System.Linq;
using CardShopEmpire.Editor;
using NUnit.Framework;
using UnityEditor;
using UnityEngine;
using UnityEngine.InputSystem;
namespace CardShopEmpire.Tests {
 public sealed class FoundationTests {
  [TestCase("", "Pack", "Description", 2, 4)]
  [TestCase("pack", "", "Description", 2, 4)]
  [TestCase("pack", "Pack", "", 2, 4)]
  [TestCase("pack", "Pack", "Description", -1, 4)]
  [TestCase("pack", "Pack", "Description", 5, 4)]
  public void RejectsInvalidProducts(string id,string name,string description,float cost,float retail){Assert.That(ProductRules.IsValid(id,name,description,cost,retail),Is.False);}
  [Test] public void RejectsNonFinitePrices(){Assert.That(ProductRules.IsValid("pack","Pack","Description",float.NaN,4),Is.False);Assert.That(ProductRules.IsValid("pack","Pack","Description",2,float.PositiveInfinity),Is.False);}
  [Test] public void DefinitionPreservesStableIdAndPrices(){
   var p=ScriptableObject.CreateInstance<ProductDefinition>();
   try {p.Initialize("rookie-pack","Rookie Pack","Fictional baseball",2,4,ProductType.BoosterPack);Assert.That(p.IsValid);Assert.That(p.StableId,Is.EqualTo("rookie-pack"));Assert.That(p.BaseRetailPrice,Is.EqualTo(4));Assert.Throws<ArgumentException>(()=>p.Initialize("bad","Bad","Bad",-1,4,ProductType.BoosterPack));Assert.That(p.StableId,Is.EqualTo("rookie-pack"));}
   finally {UnityEngine.Object.DestroyImmediate(p);}
  }
  [Test] public void InputBindingsMatchDocumentedControls(){
   using(var input=new ShopInput()){
    Assert.That(input.Move.bindings.Select(b=>b.path),Does.Contain("<Keyboard>/w"));
    Assert.That(input.Move.bindings.Select(b=>b.path),Does.Contain("<Keyboard>/a"));
    Assert.That(input.Move.bindings.Select(b=>b.path),Does.Contain("<Keyboard>/s"));
    Assert.That(input.Move.bindings.Select(b=>b.path),Does.Contain("<Keyboard>/d"));
    Assert.That(input.Look.bindings[0].path,Is.EqualTo("<Mouse>/delta"));
    Assert.That(input.Interact.bindings[0].path,Is.EqualTo("<Keyboard>/e"));
    Assert.That(input.Sprint.bindings[0].path,Is.EqualTo("<Keyboard>/leftShift"));
    Assert.That(input.Escape.bindings[0].path,Is.EqualTo("<Keyboard>/escape"));
   }
  }
  [Test] public void GeneratorIsIdempotentAndReferencesAreValid(){
   // Run on a disposable generated scene, not a hand-edited scene with unsaved work.
   StarterShopBuilder.Build();
   int count=UnityEngine.Object.FindObjectsByType<Transform>(FindObjectsSortMode.None).Length;
   string packGuid=AssetDatabase.AssetPathToGUID("Assets/_CardShopEmpire/Data/rookie-series-pack.asset");
   StarterShopBuilder.Build();StarterShopBuilder.Validate();
   Assert.That(UnityEngine.Object.FindObjectsByType<Transform>(FindObjectsSortMode.None).Length,Is.EqualTo(count));
   Assert.That(AssetDatabase.AssetPathToGUID("Assets/_CardShopEmpire/Data/rookie-series-pack.asset"),Is.EqualTo(packGuid));
   Assert.That(UnityEngine.Object.FindObjectsByType<ProductInteractable>(FindObjectsSortMode.None).Length,Is.EqualTo(29));
   Assert.That(UnityEngine.Object.FindObjectsByType<ShopSign>(FindObjectsSortMode.None).Length,Is.EqualTo(1));
  }
 }
}
