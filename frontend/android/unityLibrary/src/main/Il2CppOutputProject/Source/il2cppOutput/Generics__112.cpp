#include "pch-cpp.hpp"





template <typename R>
struct VirtualFuncInvoker0
{
	typedef R (*Func)(void*,const RuntimeMethod*);

	static inline R Invoke (Il2CppMethodSlot slot, RuntimeObject* obj)
	{
		const VirtualInvokeData& invokeData = il2cpp_codegen_get_virtual_invoke_data(slot, obj);
		return ((Func)invokeData.methodPtr)(obj,invokeData.method);
	}
};
template <typename R, typename T1>
struct VirtualFuncInvoker1
{
	typedef R (*Func)(void*,T1,const RuntimeMethod*);

	static inline R Invoke (Il2CppMethodSlot slot, RuntimeObject* obj, T1 p1)
	{
		const VirtualInvokeData& invokeData = il2cpp_codegen_get_virtual_invoke_data(slot, obj);
		return ((Func)invokeData.methodPtr)(obj,p1,invokeData.method);
	}
};
struct InterfaceActionInvoker0
{
	typedef void (*Action)(void*,const RuntimeMethod*);

	static inline void Invoke (Il2CppMethodSlot slot, RuntimeClass* declaringInterface, RuntimeObject* obj)
	{
		const VirtualInvokeData& invokeData = il2cpp_codegen_get_interface_invoke_data(slot, obj, declaringInterface);
		((Action)invokeData.methodPtr)(obj,invokeData.method);
	}
};
template <typename T1>
struct InterfaceActionInvoker1Invoker;
template <typename T1>
struct InterfaceActionInvoker1Invoker<T1*>
{
	static inline void Invoke (Il2CppMethodSlot slot, RuntimeClass* declaringInterface, RuntimeObject* obj, T1* p1)
	{
		const VirtualInvokeData& invokeData = il2cpp_codegen_get_interface_invoke_data(slot, obj, declaringInterface);
		void* params[1] = { p1 };
		invokeData.method->invoker_method(il2cpp_codegen_get_method_pointer(invokeData.method), invokeData.method, obj, params, params[0]);
	}
};
template <typename T1, typename T2>
struct InterfaceActionInvoker2
{
	typedef void (*Action)(void*,T1,T2,const RuntimeMethod*);

	static inline void Invoke (Il2CppMethodSlot slot, RuntimeClass* declaringInterface, RuntimeObject* obj, T1 p1, T2 p2)
	{
		const VirtualInvokeData& invokeData = il2cpp_codegen_get_interface_invoke_data(slot, obj, declaringInterface);
		((Action)invokeData.methodPtr)(obj,p1,p2,invokeData.method);
	}
};
template <typename T1, typename T2>
struct InterfaceActionInvoker2Invoker;
template <typename T1, typename T2>
struct InterfaceActionInvoker2Invoker<T1*, T2*>
{
	static inline void Invoke (Il2CppMethodSlot slot, RuntimeClass* declaringInterface, RuntimeObject* obj, T1* p1, T2* p2)
	{
		const VirtualInvokeData& invokeData = il2cpp_codegen_get_interface_invoke_data(slot, obj, declaringInterface);
		void* params[2] = { p1, p2 };
		invokeData.method->invoker_method(il2cpp_codegen_get_method_pointer(invokeData.method), invokeData.method, obj, params, params[1]);
	}
};
template <typename R>
struct InterfaceFuncInvoker0
{
	typedef R (*Func)(void*,const RuntimeMethod*);

	static inline R Invoke (Il2CppMethodSlot slot, RuntimeClass* declaringInterface, RuntimeObject* obj)
	{
		const VirtualInvokeData& invokeData = il2cpp_codegen_get_interface_invoke_data(slot, obj, declaringInterface);
		return ((Func)invokeData.methodPtr)(obj,invokeData.method);
	}
};
template <typename R, typename T1>
struct InterfaceFuncInvoker1
{
	typedef R (*Func)(void*,T1,const RuntimeMethod*);

	static inline R Invoke (Il2CppMethodSlot slot, RuntimeClass* declaringInterface, RuntimeObject* obj, T1 p1)
	{
		const VirtualInvokeData& invokeData = il2cpp_codegen_get_interface_invoke_data(slot, obj, declaringInterface);
		return ((Func)invokeData.methodPtr)(obj,p1,invokeData.method);
	}
};
template <typename R, typename T1>
struct InterfaceFuncInvoker1Invoker;
template <typename R, typename T1>
struct InterfaceFuncInvoker1Invoker<R, T1*>
{
	static inline R Invoke (Il2CppMethodSlot slot, RuntimeClass* declaringInterface, RuntimeObject* obj, T1* p1)
	{
		const VirtualInvokeData& invokeData = il2cpp_codegen_get_interface_invoke_data(slot, obj, declaringInterface);
		R ret;
		void* params[1] = { p1 };
		invokeData.method->invoker_method(il2cpp_codegen_get_method_pointer(invokeData.method), invokeData.method, obj, params, &ret);
		return ret;
	}
};
template <typename R, typename T1, typename T2>
struct InterfaceFuncInvoker2Invoker;
template <typename R, typename T1, typename T2>
struct InterfaceFuncInvoker2Invoker<R, T1*, T2*>
{
	static inline R Invoke (Il2CppMethodSlot slot, RuntimeClass* declaringInterface, RuntimeObject* obj, T1* p1, T2* p2)
	{
		const VirtualInvokeData& invokeData = il2cpp_codegen_get_interface_invoke_data(slot, obj, declaringInterface);
		R ret;
		void* params[2] = { p1, p2 };
		invokeData.method->invoker_method(il2cpp_codegen_get_method_pointer(invokeData.method), invokeData.method, obj, params, &ret);
		return ret;
	}
};
template <typename T1>
struct InvokerActionInvoker1;
template <typename T1>
struct InvokerActionInvoker1<T1*>
{
	static inline void Invoke (Il2CppMethodPointer methodPtr, const RuntimeMethod* method, void* obj, T1* p1)
	{
		void* params[1] = { p1 };
		method->invoker_method(methodPtr, method, obj, params, params[0]);
	}
};
template <typename T1, typename T2>
struct InvokerActionInvoker2;
template <typename T1, typename T2>
struct InvokerActionInvoker2<T1*, T2*>
{
	static inline void Invoke (Il2CppMethodPointer methodPtr, const RuntimeMethod* method, void* obj, T1* p1, T2* p2)
	{
		void* params[2] = { p1, p2 };
		method->invoker_method(methodPtr, method, obj, params, params[1]);
	}
};
template <typename R, typename T1>
struct InvokerFuncInvoker1;
template <typename R, typename T1>
struct InvokerFuncInvoker1<R, T1*>
{
	static inline R Invoke (Il2CppMethodPointer methodPtr, const RuntimeMethod* method, void* obj, T1* p1)
	{
		R ret;
		void* params[1] = { p1 };
		method->invoker_method(methodPtr, method, obj, params, &ret);
		return ret;
	}
};

struct ICollection_1_tB388ED908E2D241F56264CA971F25D9ADC1ADEC3;
struct IComparer_1_tFAD3AE9FE3CE1FB3CBB781C55DC57C986D71521E;
struct IDictionary_2_t4D3B65115D85F2C21975A2BBF4A23860F8BCD02F;
struct IEnumerable_1_t29E7244AE33B71FA0981E50D5BC73B7938F35C66;
struct IEnumerator_1_tFABD3B897F1296469E9A2DB9BCF6C89439049208;
struct IEnumerator_1_t856F6838DCBDCCBBBC1BCE5D2A2CA3FB73C9E5C9;
struct IEnumerator_1_t599F3C486FA9A5C478FFFD6420C59A6BBB7876CB;
struct IEnumerator_1_t79B912CBA712D5F76599837CD1604BEED0829411;
struct IEnumerator_1_tB22FCD08D591B657979BC015772EF132DF8E4A74;
struct IEnumerator_1_t000A232CAF2DD4044B9AFBD8982ECD3FB93809DC;
struct IEnumerator_1_tE972D340F536B04FCEE79D5799CA3F036A83451E;
struct IEnumerator_1_t90BCA6A7B2801D6A60BF1AFFCCA677FFF22E4CDA;
struct IEnumerator_1_t2AE5E199CB93D17B1E27686CC16B6667521C4040;
struct IEnumerator_1_t837F12EEBD47871CA329AE5636F57529BD8510A5;
struct IEnumerator_1_t9BAC5B5F88A0B1402733E2E2AA7CDE94AAFFA628;
struct IEnumerator_1_tDA7EC6DD9C7B117D360F4F267DE1AF00D78E8A69;
struct IEnumerator_1_t795CE62572C33D602EE9162EFF1F8EB4430DAD53;
struct IEnumerator_1_tA50BA3A8477F7D3879301E45E86A18629E2CBF24;
struct IEnumerator_1_t3EEE9F125377475C3703132A819F02052CF21AFE;
struct IEnumerator_1_t7BCCF276AC30D3D187A762A3D4C55F4DA5CF0A12;
struct IEnumerator_1_t039FD1F79231873CA31A318A129D0F6366AE3729;
struct IEnumerator_1_tA64CB30F779A737F032BA0D0CA682AC54394FFA9;
struct IList_1_t8532AAEB5D11551EBC2277A07A759536F58EA1A4;
struct IList_1_t143D8FB6289D26A7B7AD4238902B17029E83C017;
struct IList_1_t311EFF3B321589A14DAE708AD51B9BF47F025EB8;
struct IList_1_t9D41323B910C0BD2D04A6EF5DB4357FECB8F8BA3;
struct IList_1_t6D08EA7FA01BDF3C06E5BAAE0BFA0F62C86BD338;
struct IList_1_tB81C98CCFC4C70060D8C4A7773A2E018B7705389;
struct IList_1_tEBC9CEC655A21BEAC057F73381FE6A0F3284AB01;
struct IList_1_tCC943A0042E6BB5B3A81CD3BE47F5757992D48D0;
struct IList_1_t3EE866489B03C7FF7DEF9C7563B742E75B5689A2;
struct IList_1_t36B65C5A0703C973E0430B86757444E48EB4FB33;
struct IList_1_t003E5AFD433AB8547CCEE560E2BED50D6AD222BD;
struct IList_1_tDE5A2CD28934CB598C6F11B9F1968099A5148F4C;
struct IList_1_tFE2112C69F0B9C04D713EA1C40EFA14A01A0F401;
struct IList_1_tE3897FF146787D9898848BA6072D0A5ACF74AF62;
struct IList_1_tC43AD077B5DBEFD836CDC2D1D0F3257315EB484F;
struct IList_1_t45147F5693AC2CD8E1FC02E6C69D23EC082D597B;
struct IList_1_t9603583555C8EAF0519028F467C9AD34BFEE4011;
struct KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221;
struct KeyValuePair_2_tC24A74EF64A292F5C6BA77D0B04CD6620D2DE3AC;
struct List_1_t05915E9237850A58106982B7FE4BC5DA4E872E73;
struct ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E;
struct ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6;
struct ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07;
struct ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69;
struct ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7;
struct ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135;
struct ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4;
struct ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65;
struct ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568;
struct ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227;
struct ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC;
struct ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247;
struct ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466;
struct ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D;
struct ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4;
struct ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235;
struct ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434;
struct ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734;
struct ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849;
struct EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA;
struct HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5;
struct KeyValuePair_2U5BU5D_tF8154B2302178CCE00D745DBF55F703880469DFC;
struct KeyValuePair_2U5BU5D_t885F2E060B0261B18E97D336746D53BA61338F57;
struct NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0;
struct SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06;
struct UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C;
struct UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A;
struct UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B;
struct UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC;
struct UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1;
struct UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3;
struct UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6;
struct UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8;
struct UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6;
struct UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD;
struct UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00;
struct UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB;
struct UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06;
struct UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B;
struct ByteU5BU5D_tA6237BF417AE52AD70CFB4EF24A7A82613DF9031;
struct CharU5BU5D_t799905CF001DD5F13F7DBB310181FC4D8B7D0AAB;
struct DictionaryEntryU5BU5D_t410156653E754D17B5E1161CC6CF565103B63533;
struct IntPtrU5BU5D_tFD177F8C806A6921AD7150264CCC62FA00CAD832;
struct ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918;
struct StackTraceU5BU5D_t32FBCB20930EAF5BAE3F450FF75228E5450DA0DF;
struct TypeU5BU5D_t97234E1129B564EB38B8D85CAC2AD8B5B9522FFB;
struct __Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC;
struct TextureInfoU5BU5D_t0571178EAC2A0DE9A1F27F2C00A9301E04AAFB83;
struct RaycastHitDataU5BU5D_t98BBA3CE354036B88621172C27ED5C5DD7CB9279;
struct WorkRequestU5BU5D_t1B912B8BE58CF60CAF3A4FEC0A5C0F5BB6D99577;
struct AssetEntryU5BU5D_t83ECF66F13D78425A1AF86967D10F3FA0A0C123F;
struct SlotDefinitionU5BU5D_t9003D04EBDD74C44DD8490A99624A727154E1299;
struct SlotUsageEntryU5BU5D_t02CCAC4881F115443BE39FCBE8439A9DCFC1C67A;
struct UsingEntryU5BU5D_t3E321CB1464DE1D2F7FDE3790BD4AD8B72FBE811;
struct VersionInfoU5BU5D_tA86713FC86D1EDA523BC741A17D81B20A869AE64;
struct XmlSchemaObjectEntryU5BU5D_tBCEE5881A0EF3ACBC998EFA679ACBF1ED8256E27;
struct VolumeParameterChainU5BU5D_t0474622D9FD8B1CC198D56824468949D1E1C680F;
struct ContextMenuItemU5BU5D_tFD4FC81929646BCD206377E2AC8E290E93FEE279;
struct LayoutMatcherU5BU5D_t790C71C3787F12C3EE9F7ABDC24DFCEB5281F90E;
struct InstructionViewU5BU5D_t2A200DCB627CD67C1DDBD22595A355894F2646A3;
struct PassDataU5BU5D_tF21A03049926F4AE1289DBF568C76ED64042A9FC;
struct ResourceDataU5BU5D_t7EB547044DA870E25BACFEDEFCCD7821FE72022B;
struct EntryProcessingInfoU5BU5D_tAB0CBF4A4379F39BA667FBBFCB22E4174C4D319B;
struct PassCompatibilityInfoU5BU5D_t7B46D72837B465DBE4D623FD609B34DE43FE3317;
struct AABB_tE57BAC64D9F8465BBFCC4A9C66AF4E884166982A;
struct Action_tD00B0A84D7945E50C2DFFC28EFEE6ED44ED2AD07;
struct ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263;
struct ArgumentNullException_t327031E412FAB2351B0022DD5DAD47E67E597129;
struct ArgumentOutOfRangeException_tEA2822DAF62B10EEED00E0E3A341D4BAF78CF85F;
struct Binder_t91BFCE95A7057FADF4D8A1A342AFE52872246235;
struct Byte_t94D9231AC217BE4D2E004C4CD32DF6D099EA41A3;
struct EmbeddedLODBuffer_t6D75CECAC228D0710132158E77ACB46D0C43027B;
struct EntityId_t982FBD037EAC5CA077B1602A7EA40E3523AA0FC8;
struct Entry_t475ED76E31923970E7F7A6522E570E7577C487B9;
struct Graphic_tCBFCA4585A19E2B75465AECFEAC43F4016BF7931;
struct ICollection_t37E7B9DC5B4EF41D190D607F92835BF1171C0E8E;
struct IDictionary_t6D03155AF1FA9083817AA5B6AD7DEEACC26AB220;
struct IDictionaryEnumerator_tE129D608FCDB7207E0F0ECE33473CC950A83AD16;
struct IEnumerator_t7B609C2FFA6EB5167D9C62A0C32A21DE2F666DAA;
struct Instruction_t7ED95EF62BBC5003D30C1CE0FF8B1D79105A8998;
struct Int16_tB8EF286A9C33492FA6E6D6E67320BE93E794A175;
struct Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C;
struct InternalLODGroupSettings_t9F08C56422FEBE035004C6D96DE664DB1961F38D;
struct InternalMeshLodRendererSettings_t2B499712F80597BFB45A4813CC139D1BEEDEBB73;
struct InternalMeshRendererSettings_tFA0423524032AD2C34E24C53548BE032F67FC6AF;
struct ManualResetEvent_t63959486AA41A113A4353D0BF4A68E77EBA0A158;
struct MemberFilter_tF644F1AE82F611B677CE1964D5A3277DDA21D553;
struct NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A;
struct RangeInt_tDFBE4FD13857C11F21F7C3DA6B60D05341B67268;
struct RenderData_t1ABE116B2B5E0409AC699E195922516606531DC2;
struct SafeSerializationManager_tCBB85B95DFD1634237140CD892E82D06ECB3F5E6;
struct SendOrPostCallback_t5C292A12062F24027A98492F52ECFE9802AA6F0E;
struct Single_t4530F2FF86FCB0DC29F35385CA1BD21BE294761C;
struct String_t;
struct Texture_t791CBB51219779964E0E8A2ED7C1AA5F92A4A700;
struct Type_t;
struct UInt16_tF4C148C876015C212FD72652D0B6ED8CC247A455;
struct UInt64_t8F12534CC8FC4B5860F2A2CD1EE79D322E7A41AF;
struct VisualTreeAsset_tFB5BF81F0780A412AE5A7C2C552B3EEA64EA2EEB;
struct Void_t4861ACF8F4594C3437BB48B6E56783494B843915;
struct Volume_t7CAAEA22D7F13A50FAE114DE7A6986FEAC837377;
struct VolumeComponent_t8121D1F6054A9DFB3A596EE451FD65A2BFE2D7E1;
struct VolumeProfile_t9B5F2005F575A710F38A124EF81A6228CCACACE1;
struct XmlQualifiedName_t2794880B373257E4108CC3F36D7373A343ACC5B9;
struct XmlSchemaObject_t82CCD87AADB4BEF4E9DFE4C501F09EDA372AA19D;
struct float3_t7600B73F092B37F484B12910A5269F30C778D31E;
struct BufferResourceData_t0B823212ADCC9AA80412877B802DD43236781D57;
struct TextureResourceData_t0714EB0BFE2BFB2FC4E0CCFFBFE5CAA6C4B53BE3;
struct NRPInfo_tFAE346DBF564B1FDA1EBC1D2F0C3EDC93143D04F;
struct ResourceIdLists_tD6328DF3B43DB6A2B045464122D4DD5AC1629D99;

IL2CPP_EXTERN_C RuntimeClass* ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* ArgumentNullException_t327031E412FAB2351B0022DD5DAD47E67E597129_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* ArgumentOutOfRangeException_tEA2822DAF62B10EEED00E0E3A341D4BAF78CF85F_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* Char_t521A6F19B456D956AF452D926C32709DC03D6B17_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* DictionaryEntryU5BU5D_t410156653E754D17B5E1161CC6CF565103B63533_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* ICollection_t37E7B9DC5B4EF41D190D607F92835BF1171C0E8E_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* IDictionary_t6D03155AF1FA9083817AA5B6AD7DEEACC26AB220_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* IDisposable_t030E0496B4E0E4E4F086825007979AF51F7248C5_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* IEnumerable_t6331596D5DD37C462B1B8D49CF6B319B00AB7131_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* IEnumerator_t7B609C2FFA6EB5167D9C62A0C32A21DE2F666DAA_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* RuntimeObject_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* String_t_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C RuntimeClass* Type_t_il2cpp_TypeInfo_var;
IL2CPP_EXTERN_C String_t* _stringLiteral2B6D6F48C27C60C3B55391AB377D9DC8F5639AA1;
IL2CPP_EXTERN_C String_t* _stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D;
IL2CPP_EXTERN_C String_t* _stringLiteral38E3DBC7FC353425EF3A98DC8DAC6689AF5FD1BE;
IL2CPP_EXTERN_C String_t* _stringLiteral3ECE023333DCF45DE7B1FEAFFE30E295210DDD9B;
IL2CPP_EXTERN_C String_t* _stringLiteral6195D7DA68D16D4985AD1A1B4FD2841A43CDDE70;
IL2CPP_EXTERN_C String_t* _stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D;
IL2CPP_EXTERN_C String_t* _stringLiteral958BF5561D89C9A90653416FCB65BBE72DADDE1E;
IL2CPP_EXTERN_C String_t* _stringLiteral967D403A541A1026A83D548E5AD5CA800AD4EFB5;
IL2CPP_EXTERN_C String_t* _stringLiteralB829404B947F7E1629A30B5E953A49EB21CCD2ED;
IL2CPP_EXTERN_C String_t* _stringLiteralBD0381A992FDF4F7DA60E5D83689FE7FF6309CB8;
IL2CPP_EXTERN_C String_t* _stringLiteralE7AF8BCE7F42000322C784E007AAB43CA3E3D9AB;
IL2CPP_EXTERN_C String_t* _stringLiteralE7D028CCE3B6E7B61AE2C752D7AE970DA04AB7C6;
IL2CPP_EXTERN_C String_t* _stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8;
struct Exception_t_marshaled_com;
struct Exception_t_marshaled_pinvoke;

struct EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA;
struct HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5;
struct KeyValuePair_2U5BU5D_t885F2E060B0261B18E97D336746D53BA61338F57;
struct NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0;
struct SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06;
struct UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C;
struct UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A;
struct UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B;
struct UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC;
struct UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1;
struct UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3;
struct UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6;
struct UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8;
struct UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6;
struct UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD;
struct UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00;
struct UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB;
struct UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06;
struct UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B;
struct ByteU5BU5D_tA6237BF417AE52AD70CFB4EF24A7A82613DF9031;
struct DictionaryEntryU5BU5D_t410156653E754D17B5E1161CC6CF565103B63533;
struct ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918;
struct __Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC;
struct TextureInfoU5BU5D_t0571178EAC2A0DE9A1F27F2C00A9301E04AAFB83;
struct RaycastHitDataU5BU5D_t98BBA3CE354036B88621172C27ED5C5DD7CB9279;
struct WorkRequestU5BU5D_t1B912B8BE58CF60CAF3A4FEC0A5C0F5BB6D99577;
struct AssetEntryU5BU5D_t83ECF66F13D78425A1AF86967D10F3FA0A0C123F;
struct SlotDefinitionU5BU5D_t9003D04EBDD74C44DD8490A99624A727154E1299;
struct SlotUsageEntryU5BU5D_t02CCAC4881F115443BE39FCBE8439A9DCFC1C67A;
struct UsingEntryU5BU5D_t3E321CB1464DE1D2F7FDE3790BD4AD8B72FBE811;
struct VersionInfoU5BU5D_tA86713FC86D1EDA523BC741A17D81B20A869AE64;
struct XmlSchemaObjectEntryU5BU5D_tBCEE5881A0EF3ACBC998EFA679ACBF1ED8256E27;
struct VolumeParameterChainU5BU5D_t0474622D9FD8B1CC198D56824468949D1E1C680F;
struct ContextMenuItemU5BU5D_tFD4FC81929646BCD206377E2AC8E290E93FEE279;
struct LayoutMatcherU5BU5D_t790C71C3787F12C3EE9F7ABDC24DFCEB5281F90E;
struct InstructionViewU5BU5D_t2A200DCB627CD67C1DDBD22595A355894F2646A3;
struct PassDataU5BU5D_tF21A03049926F4AE1289DBF568C76ED64042A9FC;
struct ResourceDataU5BU5D_t7EB547044DA870E25BACFEDEFCCD7821FE72022B;
struct EntryProcessingInfoU5BU5D_tAB0CBF4A4379F39BA667FBBFCB22E4174C4D319B;
struct PassCompatibilityInfoU5BU5D_t7B46D72837B465DBE4D623FD609B34DE43FE3317;

IL2CPP_EXTERN_C_BEGIN
IL2CPP_EXTERN_C_END

#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
struct EmptyArray_1_tBCCAE4080E81992F81CEC3B682CED9E81A3B4D67  : public RuntimeObject
{
};
struct EmptyArray_1_tF44AD9BD1A58C47BDCB13A8D4D22873C785CC3F8  : public RuntimeObject
{
};
struct EmptyArray_1_t4505232400AEC5D181E96238357D9ACD1C992762  : public RuntimeObject
{
};
struct EmptyArray_1_t0542F0EB5C43D54C8F4ADCAB1E94F18AEA151867  : public RuntimeObject
{
};
struct EmptyArray_1_tC9589F12F2382131419143780EC4B16F75839727  : public RuntimeObject
{
};
struct EmptyArray_1_t39CC4801B12BC59D744D8F2F14920ED998228BE1  : public RuntimeObject
{
};
struct EmptyArray_1_t8F16BED9A16610B0610D3B8977C56192C7CE8275  : public RuntimeObject
{
};
struct EmptyArray_1_tE873052363E5FFF3E3324D48BF2E70EABF9FBA3E  : public RuntimeObject
{
};
struct EmptyArray_1_tE694D0227F619BC5A10811AC94E5B6D8EE0CBD57  : public RuntimeObject
{
};
struct EmptyArray_1_tA05DBCB91EE064FE54203B7543F218C61D4C292D  : public RuntimeObject
{
};
struct EmptyArray_1_tFEE1A4E0C8058B54F07835CFB63F231873095076  : public RuntimeObject
{
};
struct EmptyArray_1_t8505E6935DD4C58400550971BB8321BD8CE9D6CF  : public RuntimeObject
{
};
struct EmptyArray_1_tA0B73630739AC85F81DDEFE547CAFB1C84FB72C6  : public RuntimeObject
{
};
struct EmptyArray_1_t1347A16AC3E72AFF909DAA98EED1FA11A4470068  : public RuntimeObject
{
};
struct EmptyArray_1_t5058CECA8099AD79767245351D26A5CB48C84746  : public RuntimeObject
{
};
struct EmptyArray_1_t47AB7FAF9E162BBE81FCF7964F3209ECF415B0A4  : public RuntimeObject
{
};
struct EmptyArray_1_t410AE8CFE5DA7B6BD5DA6669225E54549802E603  : public RuntimeObject
{
};
struct EmptyArray_1_t15EC9BF1140A58A19136B22B04EFD7559BBCC2D4  : public RuntimeObject
{
};
struct KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221  : public RuntimeObject
{
	RuntimeObject* ____collection;
	RuntimeObject* ____syncRoot;
};
struct MemoryManager_1_tB90442C8E0A1B9C0F8A3B603FD50501A1BADAC6E  : public RuntimeObject
{
};
struct MemoryManager_1_tED55276A18D77758B15A7A09B9C0D4DB79480487  : public RuntimeObject
{
};
struct ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434  : public RuntimeObject
{
	RuntimeObject* ___list;
	RuntimeObject* ____syncRoot;
};
struct ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734  : public RuntimeObject
{
	RuntimeObject* ___m_dictionary;
	RuntimeObject* ____syncRoot;
	KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221* ____keys;
	ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849* ____values;
};
struct ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849  : public RuntimeObject
{
	RuntimeObject* ____collection;
	RuntimeObject* ____syncRoot;
};
struct MemberInfo_t  : public RuntimeObject
{
};
struct String_t  : public RuntimeObject
{
	int32_t ____stringLength;
	Il2CppChar ____firstChar;
};
struct ValueType_t6D9B272BD21782F0A9A14F2E41F85A50E97A986F  : public RuntimeObject
{
};
struct ValueType_t6D9B272BD21782F0A9A14F2E41F85A50E97A986F_marshaled_pinvoke
{
};
struct ValueType_t6D9B272BD21782F0A9A14F2E41F85A50E97A986F_marshaled_com
{
};
struct DictionaryEnumerator_tA07B53C91CCF243B3DDF48825CD4F71A6835CD77 
{
	RuntimeObject* ____dictionary;
	RuntimeObject* ____enumerator;
};
struct HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5 
{
	int32_t ___hash;
	int32_t ___lastFrameUsed;
	Il2CppSharedGenericObject* ___compiledGraph;
};
typedef Il2CppFullySharedGenericStruct KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669;
struct Memory_1_tB7CEF4416F5014E364267478CEF016A4AC5C0036 
{
	RuntimeObject* ____object;
	int32_t ____index;
	int32_t ____length;
};
#ifndef Memory_1_t56F63672B8E752B13E0BBBBD034BA3C1F6CFDC17_marshaled_pinvoke_define
#define Memory_1_t56F63672B8E752B13E0BBBBD034BA3C1F6CFDC17_marshaled_pinvoke_define
struct Memory_1_t56F63672B8E752B13E0BBBBD034BA3C1F6CFDC17_marshaled_pinvoke
{
	Il2CppIUnknown* ____object;
	int32_t ____index;
	int32_t ____length;
};
#endif
#ifndef Memory_1_t56F63672B8E752B13E0BBBBD034BA3C1F6CFDC17_marshaled_com_define
#define Memory_1_t56F63672B8E752B13E0BBBBD034BA3C1F6CFDC17_marshaled_com_define
struct Memory_1_t56F63672B8E752B13E0BBBBD034BA3C1F6CFDC17_marshaled_com
{
	Il2CppIUnknown* ____object;
	int32_t ____index;
	int32_t ____length;
};
#endif
struct Memory_1_t762D61B435521D1706EEDC25CA8C8EA1AE19AFEA 
{
	RuntimeObject* ____object;
	int32_t ____index;
	int32_t ____length;
};
#ifndef Memory_1_t56F63672B8E752B13E0BBBBD034BA3C1F6CFDC17_marshaled_pinvoke_define
#define Memory_1_t56F63672B8E752B13E0BBBBD034BA3C1F6CFDC17_marshaled_pinvoke_define
struct Memory_1_t56F63672B8E752B13E0BBBBD034BA3C1F6CFDC17_marshaled_pinvoke
{
	Il2CppIUnknown* ____object;
	int32_t ____index;
	int32_t ____length;
};
#endif
#ifndef Memory_1_t56F63672B8E752B13E0BBBBD034BA3C1F6CFDC17_marshaled_com_define
#define Memory_1_t56F63672B8E752B13E0BBBBD034BA3C1F6CFDC17_marshaled_com_define
struct Memory_1_t56F63672B8E752B13E0BBBBD034BA3C1F6CFDC17_marshaled_com
{
	Il2CppIUnknown* ____object;
	int32_t ____index;
	int32_t ____length;
};
#endif
struct ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399 
{
	RuntimeObject* ____object;
	int32_t ____index;
	int32_t ____length;
};
#ifndef ReadOnlyMemory_1_t766DD3EE24B08138FB23CBC5B315D83C6E1272F5_marshaled_pinvoke_define
#define ReadOnlyMemory_1_t766DD3EE24B08138FB23CBC5B315D83C6E1272F5_marshaled_pinvoke_define
struct ReadOnlyMemory_1_t766DD3EE24B08138FB23CBC5B315D83C6E1272F5_marshaled_pinvoke
{
	Il2CppIUnknown* ____object;
	int32_t ____index;
	int32_t ____length;
};
#endif
#ifndef ReadOnlyMemory_1_t766DD3EE24B08138FB23CBC5B315D83C6E1272F5_marshaled_com_define
#define ReadOnlyMemory_1_t766DD3EE24B08138FB23CBC5B315D83C6E1272F5_marshaled_com_define
struct ReadOnlyMemory_1_t766DD3EE24B08138FB23CBC5B315D83C6E1272F5_marshaled_com
{
	Il2CppIUnknown* ____object;
	int32_t ____index;
	int32_t ____length;
};
#endif
struct ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4 
{
	RuntimeObject* ____object;
	int32_t ____index;
	int32_t ____length;
};
#ifndef ReadOnlyMemory_1_t766DD3EE24B08138FB23CBC5B315D83C6E1272F5_marshaled_pinvoke_define
#define ReadOnlyMemory_1_t766DD3EE24B08138FB23CBC5B315D83C6E1272F5_marshaled_pinvoke_define
struct ReadOnlyMemory_1_t766DD3EE24B08138FB23CBC5B315D83C6E1272F5_marshaled_pinvoke
{
	Il2CppIUnknown* ____object;
	int32_t ____index;
	int32_t ____length;
};
#endif
#ifndef ReadOnlyMemory_1_t766DD3EE24B08138FB23CBC5B315D83C6E1272F5_marshaled_com_define
#define ReadOnlyMemory_1_t766DD3EE24B08138FB23CBC5B315D83C6E1272F5_marshaled_com_define
struct ReadOnlyMemory_1_t766DD3EE24B08138FB23CBC5B315D83C6E1272F5_marshaled_com
{
	Il2CppIUnknown* ____object;
	int32_t ____index;
	int32_t ____length;
};
#endif
struct Boolean_t09A6377A54BE2F9E6985A8149F19234FD7DDFE22 
{
	bool ___m_value;
};
struct Byte_t94D9231AC217BE4D2E004C4CD32DF6D099EA41A3 
{
	uint8_t ___m_value;
};
struct Char_t521A6F19B456D956AF452D926C32709DC03D6B17 
{
	Il2CppChar ___m_value;
};
struct DictionaryEntry_t171080F37B311C25AA9E75888F9C9D703FA721BB 
{
	RuntimeObject* ____key;
	RuntimeObject* ____value;
};
struct DictionaryEntry_t171080F37B311C25AA9E75888F9C9D703FA721BB_marshaled_pinvoke
{
	Il2CppIUnknown* ____key;
	Il2CppIUnknown* ____value;
};
struct DictionaryEntry_t171080F37B311C25AA9E75888F9C9D703FA721BB_marshaled_com
{
	Il2CppIUnknown* ____key;
	Il2CppIUnknown* ____value;
};
struct EntityId_t982FBD037EAC5CA077B1602A7EA40E3523AA0FC8 
{
	union
	{
		struct
		{
			uint64_t ___m_rawData;
		};
		uint8_t EntityId_t982FBD037EAC5CA077B1602A7EA40E3523AA0FC8__padding[8];
	};
};
struct Enum_t2A1A94B24E3B776EEF4E5E485E290BB9D4D072E2  : public ValueType_t6D9B272BD21782F0A9A14F2E41F85A50E97A986F
{
};
struct Enum_t2A1A94B24E3B776EEF4E5E485E290BB9D4D072E2_marshaled_pinvoke
{
};
struct Enum_t2A1A94B24E3B776EEF4E5E485E290BB9D4D072E2_marshaled_com
{
};
#pragma pack(push, tp, 1)
struct FixedBytes16Align8_t94D49B0852778B92D3912ABC4979B11ADF6ECEE4 
{
	union
	{
		struct
		{
			union
			{
				#pragma pack(push, tp, 1)
				struct
				{
					uint64_t ___byte0000;
				};
				#pragma pack(pop, tp)
				struct
				{
					uint64_t ___byte0000_forAlignmentOnly;
				};
				#pragma pack(push, tp, 1)
				struct
				{
					char ___byte0008_OffsetPadding[8];
					uint64_t ___byte0008;
				};
				#pragma pack(pop, tp)
				struct
				{
					char ___byte0008_OffsetPadding_forAlignmentOnly[8];
					uint64_t ___byte0008_forAlignmentOnly;
				};
			};
		};
		uint8_t FixedBytes16Align8_t94D49B0852778B92D3912ABC4979B11ADF6ECEE4__padding[16];
	};
};
#pragma pack(pop, tp)
struct InputDeviceMatcher_tF9BA551C8BB4AE41672366A7EBEA951543E0C555 
{
	KeyValuePair_2U5BU5D_tF8154B2302178CCE00D745DBF55F703880469DFC* ___m_Patterns;
};
struct InputDeviceMatcher_tF9BA551C8BB4AE41672366A7EBEA951543E0C555_marshaled_pinvoke
{
	KeyValuePair_2_tC24A74EF64A292F5C6BA77D0B04CD6620D2DE3AC* ___m_Patterns;
};
struct InputDeviceMatcher_tF9BA551C8BB4AE41672366A7EBEA951543E0C555_marshaled_com
{
	KeyValuePair_2_tC24A74EF64A292F5C6BA77D0B04CD6620D2DE3AC* ___m_Patterns;
};
struct Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C 
{
	int32_t ___m_value;
};
struct IntPtr_t 
{
	void* ___m_value;
};
struct InternedString_t8D62A48CB7D85AAE9CFCCCFB0A77AC2844905735 
{
	String_t* ___m_StringOriginalCase;
	String_t* ___m_StringLowerCase;
};
struct InternedString_t8D62A48CB7D85AAE9CFCCCFB0A77AC2844905735_marshaled_pinvoke
{
	char* ___m_StringOriginalCase;
	char* ___m_StringLowerCase;
};
struct InternedString_t8D62A48CB7D85AAE9CFCCCFB0A77AC2844905735_marshaled_com
{
	Il2CppChar* ___m_StringOriginalCase;
	Il2CppChar* ___m_StringLowerCase;
};
struct UInt64_t8F12534CC8FC4B5860F2A2CD1EE79D322E7A41AF 
{
	uint64_t ___m_value;
};
struct Vector2_t1FD6F485C871E832B347AB2DC8CBA08B739D8DF7 
{
	float ___x;
	float ___y;
};
struct Vector3_t24C512C7B96BBABAD472002D0BA2BDA40A5A80B2 
{
	float ___x;
	float ___y;
	float ___z;
};
struct Void_t4861ACF8F4594C3437BB48B6E56783494B843915 
{
	union
	{
		struct
		{
		};
		uint8_t Void_t4861ACF8F4594C3437BB48B6E56783494B843915__padding[1];
	};
};
struct AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 
{
	uint16_t ___Index;
	uint16_t ___Version;
};
struct TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B 
{
	Texture_t791CBB51219779964E0E8A2ED7C1AA5F92A4A700* ___texture;
	bool ___dynamic;
	int32_t ___refCount;
};
struct TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B_marshaled_pinvoke
{
	Texture_t791CBB51219779964E0E8A2ED7C1AA5F92A4A700* ___texture;
	int32_t ___dynamic;
	int32_t ___refCount;
};
struct TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B_marshaled_com
{
	Texture_t791CBB51219779964E0E8A2ED7C1AA5F92A4A700* ___texture;
	int32_t ___dynamic;
	int32_t ___refCount;
};
struct WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 
{
	SendOrPostCallback_t5C292A12062F24027A98492F52ECFE9802AA6F0E* ___m_DelagateCallback;
	RuntimeObject* ___m_DelagateState;
	ManualResetEvent_t63959486AA41A113A4353D0BF4A68E77EBA0A158* ___m_WaitHandle;
};
struct WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44_marshaled_pinvoke
{
	Il2CppMethodPointer ___m_DelagateCallback;
	Il2CppIUnknown* ___m_DelagateState;
	ManualResetEvent_t63959486AA41A113A4353D0BF4A68E77EBA0A158* ___m_WaitHandle;
};
struct WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44_marshaled_com
{
	Il2CppMethodPointer ___m_DelagateCallback;
	Il2CppIUnknown* ___m_DelagateState;
	ManualResetEvent_t63959486AA41A113A4353D0BF4A68E77EBA0A158* ___m_WaitHandle;
};
struct SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 
{
	String_t* ___name;
	int32_t ___insertionPointId;
};
struct SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8_marshaled_pinvoke
{
	char* ___name;
	int32_t ___insertionPointId;
};
struct SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8_marshaled_com
{
	Il2CppChar* ___name;
	int32_t ___insertionPointId;
};
struct SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 
{
	String_t* ___slotName;
	int32_t ___assetId;
};
struct SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76_marshaled_pinvoke
{
	char* ___slotName;
	int32_t ___assetId;
};
struct SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76_marshaled_com
{
	Il2CppChar* ___slotName;
	int32_t ___assetId;
};
struct UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 
{
	String_t* ___alias;
	String_t* ___path;
	VisualTreeAsset_tFB5BF81F0780A412AE5A7C2C552B3EEA64EA2EEB* ___asset;
};
struct UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484_marshaled_pinvoke
{
	char* ___alias;
	char* ___path;
	VisualTreeAsset_tFB5BF81F0780A412AE5A7C2C552B3EEA64EA2EEB* ___asset;
};
struct UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484_marshaled_com
{
	Il2CppChar* ___alias;
	Il2CppChar* ___path;
	VisualTreeAsset_tFB5BF81F0780A412AE5A7C2C552B3EEA64EA2EEB* ___asset;
};
struct VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 
{
	RuntimeObject* ___source;
	int64_t ___version;
};
struct VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8_marshaled_pinvoke
{
	Il2CppIUnknown* ___source;
	int64_t ___version;
};
struct VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8_marshaled_com
{
	Il2CppIUnknown* ___source;
	int64_t ___version;
};
struct XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD 
{
	XmlQualifiedName_t2794880B373257E4108CC3F36D7373A343ACC5B9* ___qname;
	XmlSchemaObject_t82CCD87AADB4BEF4E9DFE4C501F09EDA372AA19D* ___xso;
};
struct XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD_marshaled_pinvoke
{
	XmlQualifiedName_t2794880B373257E4108CC3F36D7373A343ACC5B9* ___qname;
	XmlSchemaObject_t82CCD87AADB4BEF4E9DFE4C501F09EDA372AA19D* ___xso;
};
struct XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD_marshaled_com
{
	XmlQualifiedName_t2794880B373257E4108CC3F36D7373A343ACC5B9* ___qname;
	XmlSchemaObject_t82CCD87AADB4BEF4E9DFE4C501F09EDA372AA19D* ___xso;
};
struct ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 
{
	String_t* ___displayName;
	Action_tD00B0A84D7945E50C2DFFC28EFEE6ED44ED2AD07* ___action;
};
struct ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9_marshaled_pinvoke
{
	char* ___displayName;
	Il2CppMethodPointer ___action;
};
struct ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9_marshaled_com
{
	Il2CppChar* ___displayName;
	Il2CppMethodPointer ___action;
};
struct NameAndTooltip_tA6656221A6E70C8409CFCBAF6CCEC9C718E344D4 
{
	String_t* ___name;
	String_t* ___tooltip;
};
struct NameAndTooltip_tA6656221A6E70C8409CFCBAF6CCEC9C718E344D4_marshaled_pinvoke
{
	char* ___name;
	char* ___tooltip;
};
struct NameAndTooltip_tA6656221A6E70C8409CFCBAF6CCEC9C718E344D4_marshaled_com
{
	Il2CppChar* ___name;
	Il2CppChar* ___tooltip;
};
struct InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D 
{
	int32_t ____index;
	int32_t ____stackDepth;
	int32_t ____continuationsDepth;
	String_t* ____name;
	Instruction_t7ED95EF62BBC5003D30C1CE0FF8B1D79105A8998* ____instruction;
};
struct InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D_marshaled_pinvoke
{
	int32_t ____index;
	int32_t ____stackDepth;
	int32_t ____continuationsDepth;
	char* ____name;
	Instruction_t7ED95EF62BBC5003D30C1CE0FF8B1D79105A8998* ____instruction;
};
struct InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D_marshaled_com
{
	int32_t ____index;
	int32_t ____stackDepth;
	int32_t ____continuationsDepth;
	Il2CppChar* ____name;
	Instruction_t7ED95EF62BBC5003D30C1CE0FF8B1D79105A8998* ____instruction;
};
struct PassScriptInfo_t8619301849E12A8422C5C4BF3D19F5D7410A0A31 
{
	String_t* ___filePath;
	int32_t ___line;
};
struct PassScriptInfo_t8619301849E12A8422C5C4BF3D19F5D7410A0A31_marshaled_pinvoke
{
	char* ___filePath;
	int32_t ___line;
};
struct PassScriptInfo_t8619301849E12A8422C5C4BF3D19F5D7410A0A31_marshaled_com
{
	Il2CppChar* ___filePath;
	int32_t ___line;
};
struct ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 
{
	String_t* ___name;
	bool ___imported;
	int32_t ___creationPassIndex;
	int32_t ___releasePassIndex;
	List_1_t05915E9237850A58106982B7FE4BC5DA4E872E73* ___consumerList;
	List_1_t05915E9237850A58106982B7FE4BC5DA4E872E73* ___producerList;
	bool ___memoryless;
	TextureResourceData_t0714EB0BFE2BFB2FC4E0CCFFBFE5CAA6C4B53BE3* ___textureData;
	BufferResourceData_t0B823212ADCC9AA80412877B802DD43236781D57* ___bufferData;
};
struct ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3_marshaled_pinvoke
{
	char* ___name;
	int32_t ___imported;
	int32_t ___creationPassIndex;
	int32_t ___releasePassIndex;
	List_1_t05915E9237850A58106982B7FE4BC5DA4E872E73* ___consumerList;
	List_1_t05915E9237850A58106982B7FE4BC5DA4E872E73* ___producerList;
	int32_t ___memoryless;
	TextureResourceData_t0714EB0BFE2BFB2FC4E0CCFFBFE5CAA6C4B53BE3* ___textureData;
	BufferResourceData_t0B823212ADCC9AA80412877B802DD43236781D57* ___bufferData;
};
struct ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3_marshaled_com
{
	Il2CppChar* ___name;
	int32_t ___imported;
	int32_t ___creationPassIndex;
	int32_t ___releasePassIndex;
	List_1_t05915E9237850A58106982B7FE4BC5DA4E872E73* ___consumerList;
	List_1_t05915E9237850A58106982B7FE4BC5DA4E872E73* ___producerList;
	int32_t ___memoryless;
	TextureResourceData_t0714EB0BFE2BFB2FC4E0CCFFBFE5CAA6C4B53BE3* ___textureData;
	BufferResourceData_t0B823212ADCC9AA80412877B802DD43236781D57* ___bufferData;
};
struct PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 
{
	String_t* ___message;
	bool ___isCompatible;
};
struct PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3_marshaled_pinvoke
{
	char* ___message;
	int32_t ___isCompatible;
};
struct PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3_marshaled_com
{
	Il2CppChar* ___message;
	int32_t ___isCompatible;
};
struct ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 
{
	intptr_t ____value;
};
struct ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A 
{
	intptr_t ____value;
};
struct ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 
{
	intptr_t ____value;
};
struct ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F 
{
	intptr_t ____value;
};
struct ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F 
{
	intptr_t ____value;
};
struct ByReference_1_tC71D682DBC538763066DF671429413D25394012A 
{
	intptr_t ____value;
};
struct ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D 
{
	intptr_t ____value;
};
struct ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD 
{
	intptr_t ____value;
};
struct ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 
{
	intptr_t ____value;
};
struct ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E 
{
	intptr_t ____value;
};
struct ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA 
{
	intptr_t ____value;
};
struct ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 
{
	intptr_t ____value;
};
struct ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 
{
	intptr_t ____value;
};
struct ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 
{
	intptr_t ____value;
};
struct ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 
{
	intptr_t ____value;
};
struct ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 
{
	intptr_t ____value;
};
struct ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 
{
	intptr_t ____value;
};
struct ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 
{
	intptr_t ____value;
};
struct ByReference_1_t9C85BCCAAF8C525B6C06B07E922D8D217BE8D6FC 
{
	intptr_t ____value;
};
struct ByReference_1_t607C1F3BC28B0E21B969461CDB0720FB01A82141 
{
	intptr_t ____value;
};
struct LazyLoadReference_1_tD57A582D5A28F3AE34FBB810985EF171325FAF1B 
{
	EntityId_t982FBD037EAC5CA077B1602A7EA40E3523AA0FC8 ___m_EntityId;
};
struct ReadOnlyNativeVector_1_t0DE13C6BA89CEDB2D828D3F45AA93F7EC7AD4A0E 
{
	intptr_t ___m_Ptr;
	int32_t ___m_Count;
};
struct ReadOnlyNativeVector_1_t53A6814B9ECC2D21CA860DE85D9AEB86D11F6F17 
{
	intptr_t ___m_Ptr;
	int32_t ___m_Count;
};
struct ReadOnlyNativeVector_1_tE45C179B8DFEAD70E1F59D744D5C6999873C0FFC 
{
	intptr_t ___m_Ptr;
	int32_t ___m_Count;
};
struct UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD 
{
	AABB_tE57BAC64D9F8465BBFCC4A9C66AF4E884166982A* ___Ptr;
	int32_t ___m_length;
	int32_t ___m_capacity;
	AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 ___Allocator;
	int32_t ___padding;
};
struct UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D 
{
	uint8_t* ___Ptr;
	int32_t ___m_length;
	int32_t ___m_capacity;
	AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 ___Allocator;
	int32_t ___padding;
};
struct UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692 
{
	EmbeddedLODBuffer_t6D75CECAC228D0710132158E77ACB46D0C43027B* ___Ptr;
	int32_t ___m_length;
	int32_t ___m_capacity;
	AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 ___Allocator;
	int32_t ___padding;
};
struct UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B 
{
	EntityId_t982FBD037EAC5CA077B1602A7EA40E3523AA0FC8* ___Ptr;
	int32_t ___m_length;
	int32_t ___m_capacity;
	AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 ___Allocator;
	int32_t ___padding;
};
struct UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0 
{
	int16_t* ___Ptr;
	int32_t ___m_length;
	int32_t ___m_capacity;
	AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 ___Allocator;
	int32_t ___padding;
};
struct UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718 
{
	int32_t* ___Ptr;
	int32_t ___m_length;
	int32_t ___m_capacity;
	AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 ___Allocator;
	int32_t ___padding;
};
struct UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF 
{
	InternalLODGroupSettings_t9F08C56422FEBE035004C6D96DE664DB1961F38D* ___Ptr;
	int32_t ___m_length;
	int32_t ___m_capacity;
	AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 ___Allocator;
	int32_t ___padding;
};
struct UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6 
{
	InternalMeshLodRendererSettings_t2B499712F80597BFB45A4813CC139D1BEEDEBB73* ___Ptr;
	int32_t ___m_length;
	int32_t ___m_capacity;
	AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 ___Allocator;
	int32_t ___padding;
};
struct UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4 
{
	InternalMeshRendererSettings_tFA0423524032AD2C34E24C53548BE032F67FC6AF* ___Ptr;
	int32_t ___m_length;
	int32_t ___m_capacity;
	AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 ___Allocator;
	int32_t ___padding;
};
struct UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A 
{
	RangeInt_tDFBE4FD13857C11F21F7C3DA6B60D05341B67268* ___Ptr;
	int32_t ___m_length;
	int32_t ___m_capacity;
	AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 ___Allocator;
	int32_t ___padding;
};
struct UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73 
{
	float* ___Ptr;
	int32_t ___m_length;
	int32_t ___m_capacity;
	AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 ___Allocator;
	int32_t ___padding;
};
struct UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516 
{
	uint16_t* ___Ptr;
	int32_t ___m_length;
	int32_t ___m_capacity;
	AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 ___Allocator;
	int32_t ___padding;
};
struct UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB 
{
	uint64_t* ___Ptr;
	int32_t ___m_length;
	int32_t ___m_capacity;
	AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 ___Allocator;
	int32_t ___padding;
};
struct UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8 
{
	float3_t7600B73F092B37F484B12910A5269F30C778D31E* ___Ptr;
	int32_t ___m_length;
	int32_t ___m_capacity;
	AllocatorHandle_t3CA09720B1F89F91A8DDBA95E74C28A1EC3E3148 ___Allocator;
	int32_t ___padding;
};
struct Allocator_t996642592271AAD9EE688F142741D512C07B5824 
{
	int32_t ___value__;
};
struct Exception_t  : public RuntimeObject
{
	String_t* ____className;
	String_t* ____message;
	RuntimeObject* ____data;
	Exception_t* ____innerException;
	String_t* ____helpURL;
	RuntimeObject* ____stackTrace;
	String_t* ____stackTraceString;
	String_t* ____remoteStackTraceString;
	int32_t ____remoteStackIndex;
	RuntimeObject* ____dynamicMethods;
	int32_t ____HResult;
	String_t* ____source;
	SafeSerializationManager_tCBB85B95DFD1634237140CD892E82D06ECB3F5E6* ____safeSerializationManager;
	StackTraceU5BU5D_t32FBCB20930EAF5BAE3F450FF75228E5450DA0DF* ___captured_traces;
	IntPtrU5BU5D_tFD177F8C806A6921AD7150264CCC62FA00CAD832* ___native_trace_ips;
	int32_t ___caught_in_unmanaged;
};
struct Exception_t_marshaled_pinvoke
{
	char* ____className;
	char* ____message;
	RuntimeObject* ____data;
	Exception_t_marshaled_pinvoke* ____innerException;
	char* ____helpURL;
	Il2CppIUnknown* ____stackTrace;
	char* ____stackTraceString;
	char* ____remoteStackTraceString;
	int32_t ____remoteStackIndex;
	Il2CppIUnknown* ____dynamicMethods;
	int32_t ____HResult;
	char* ____source;
	SafeSerializationManager_tCBB85B95DFD1634237140CD892E82D06ECB3F5E6* ____safeSerializationManager;
	StackTraceU5BU5D_t32FBCB20930EAF5BAE3F450FF75228E5450DA0DF* ___captured_traces;
	Il2CppSafeArray* ___native_trace_ips;
	int32_t ___caught_in_unmanaged;
};
struct Exception_t_marshaled_com
{
	Il2CppChar* ____className;
	Il2CppChar* ____message;
	RuntimeObject* ____data;
	Exception_t_marshaled_com* ____innerException;
	Il2CppChar* ____helpURL;
	Il2CppIUnknown* ____stackTrace;
	Il2CppChar* ____stackTraceString;
	Il2CppChar* ____remoteStackTraceString;
	int32_t ____remoteStackIndex;
	Il2CppIUnknown* ____dynamicMethods;
	int32_t ____HResult;
	Il2CppChar* ____source;
	SafeSerializationManager_tCBB85B95DFD1634237140CD892E82D06ECB3F5E6* ____safeSerializationManager;
	StackTraceU5BU5D_t32FBCB20930EAF5BAE3F450FF75228E5450DA0DF* ___captured_traces;
	Il2CppSafeArray* ___native_trace_ips;
	int32_t ___caught_in_unmanaged;
};
struct ExceptionArgument_t60E7F8D9DE5362CBE9365893983C30302D83B778 
{
	int32_t ___value__;
};
struct ExceptionResource_t609A85E253A4E615583553D91D839E2E79FDFBD9 
{
	int32_t ___value__;
};
#pragma pack(push, tp, 1)
struct FixedBytes32Align8_t07C7D543B487721FF9B88AD85209956AE423A779 
{
	union
	{
		struct
		{
			union
			{
				#pragma pack(push, tp, 1)
				struct
				{
					FixedBytes16Align8_t94D49B0852778B92D3912ABC4979B11ADF6ECEE4 ___offset0000;
				};
				#pragma pack(pop, tp)
				struct
				{
					FixedBytes16Align8_t94D49B0852778B92D3912ABC4979B11ADF6ECEE4 ___offset0000_forAlignmentOnly;
				};
				#pragma pack(push, tp, 1)
				struct
				{
					char ___offset0016_OffsetPadding[16];
					FixedBytes16Align8_t94D49B0852778B92D3912ABC4979B11ADF6ECEE4 ___offset0016;
				};
				#pragma pack(pop, tp)
				struct
				{
					char ___offset0016_OffsetPadding_forAlignmentOnly[16];
					FixedBytes16Align8_t94D49B0852778B92D3912ABC4979B11ADF6ECEE4 ___offset0016_forAlignmentOnly;
				};
			};
		};
		uint8_t FixedBytes32Align8_t07C7D543B487721FF9B88AD85209956AE423A779__padding[32];
	};
};
#pragma pack(pop, tp)
struct RenderGraphPassType_tD00EC2DAA135C660EE7E71652291A4672104EA2D 
{
	int32_t ___value__;
};
struct RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B 
{
	intptr_t ___value;
};
struct SelectorAccelerationTableType_t29E86C4FCF992B838F757327FF6002927A251B9A 
{
	int32_t ___value__;
};
struct RawData_t37CAF2D3F74B7723974ED7CEEE9B297D8FA64ED0  : public RuntimeObject
{
	intptr_t ___Bounds;
	intptr_t ___Count;
	uint8_t ___Data;
};
struct RawData_t37CAF2D3F74B7723974ED7CEEE9B297D8FA64ED0_marshaled_pinvoke
{
	intptr_t ___Bounds;
	intptr_t ___Count;
	uint8_t ___Data;
};
struct RawData_t37CAF2D3F74B7723974ED7CEEE9B297D8FA64ED0_marshaled_com
{
	intptr_t ___Bounds;
	intptr_t ___Count;
	uint8_t ___Data;
};
struct RaycastHitData_t5EAB266730389AB27715962670C2512800451841 
{
	Graphic_tCBFCA4585A19E2B75465AECFEAC43F4016BF7931* ___U3CgraphicU3Ek__BackingField;
	Vector3_t24C512C7B96BBABAD472002D0BA2BDA40A5A80B2 ___U3CworldHitPositionU3Ek__BackingField;
	Vector2_t1FD6F485C871E832B347AB2DC8CBA08B739D8DF7 ___U3CscreenPositionU3Ek__BackingField;
	float ___U3CdistanceU3Ek__BackingField;
};
struct RaycastHitData_t5EAB266730389AB27715962670C2512800451841_marshaled_pinvoke
{
	Graphic_tCBFCA4585A19E2B75465AECFEAC43F4016BF7931* ___U3CgraphicU3Ek__BackingField;
	Vector3_t24C512C7B96BBABAD472002D0BA2BDA40A5A80B2 ___U3CworldHitPositionU3Ek__BackingField;
	Vector2_t1FD6F485C871E832B347AB2DC8CBA08B739D8DF7 ___U3CscreenPositionU3Ek__BackingField;
	float ___U3CdistanceU3Ek__BackingField;
};
struct RaycastHitData_t5EAB266730389AB27715962670C2512800451841_marshaled_com
{
	Graphic_tCBFCA4585A19E2B75465AECFEAC43F4016BF7931* ___U3CgraphicU3Ek__BackingField;
	Vector3_t24C512C7B96BBABAD472002D0BA2BDA40A5A80B2 ___U3CworldHitPositionU3Ek__BackingField;
	Vector2_t1FD6F485C871E832B347AB2DC8CBA08B739D8DF7 ___U3CscreenPositionU3Ek__BackingField;
	float ___U3CdistanceU3Ek__BackingField;
};
struct VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E 
{
	NameAndTooltip_tA6656221A6E70C8409CFCBAF6CCEC9C718E344D4 ___nameAndTooltip;
	VolumeProfile_t9B5F2005F575A710F38A124EF81A6228CCACACE1* ___volumeProfile;
	VolumeComponent_t8121D1F6054A9DFB3A596EE451FD65A2BFE2D7E1* ___volumeComponent;
	Volume_t7CAAEA22D7F13A50FAE114DE7A6986FEAC837377* ___volume;
};
struct VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E_marshaled_pinvoke
{
	NameAndTooltip_tA6656221A6E70C8409CFCBAF6CCEC9C718E344D4_marshaled_pinvoke ___nameAndTooltip;
	VolumeProfile_t9B5F2005F575A710F38A124EF81A6228CCACACE1* ___volumeProfile;
	VolumeComponent_t8121D1F6054A9DFB3A596EE451FD65A2BFE2D7E1* ___volumeComponent;
	Volume_t7CAAEA22D7F13A50FAE114DE7A6986FEAC837377* ___volume;
};
struct VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E_marshaled_com
{
	NameAndTooltip_tA6656221A6E70C8409CFCBAF6CCEC9C718E344D4_marshaled_com ___nameAndTooltip;
	VolumeProfile_t9B5F2005F575A710F38A124EF81A6228CCACACE1* ___volumeProfile;
	VolumeComponent_t8121D1F6054A9DFB3A596EE451FD65A2BFE2D7E1* ___volumeComponent;
	Volume_t7CAAEA22D7F13A50FAE114DE7A6986FEAC837377* ___volume;
};
struct LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 
{
	InternedString_t8D62A48CB7D85AAE9CFCCCFB0A77AC2844905735 ___layoutName;
	InputDeviceMatcher_tF9BA551C8BB4AE41672366A7EBEA951543E0C555 ___deviceMatcher;
};
struct LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6_marshaled_pinvoke
{
	InternedString_t8D62A48CB7D85AAE9CFCCCFB0A77AC2844905735_marshaled_pinvoke ___layoutName;
	InputDeviceMatcher_tF9BA551C8BB4AE41672366A7EBEA951543E0C555_marshaled_pinvoke ___deviceMatcher;
};
struct LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6_marshaled_com
{
	InternedString_t8D62A48CB7D85AAE9CFCCCFB0A77AC2844905735_marshaled_com ___layoutName;
	InputDeviceMatcher_tF9BA551C8BB4AE41672366A7EBEA951543E0C555_marshaled_com ___deviceMatcher;
};
struct VisualsProcessingType_t19983E0076886C15ED2761057B9992989A710ECC 
{
	int32_t ___value__;
};
struct FixedList32Bytes_1_t02D797FE0EF11E83016BA95DD7B282490C8A472E 
{
	alignas(8) FixedBytes32Align8_t07C7D543B487721FF9B88AD85209956AE423A779 ___data;
};
struct NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62 
{
	void* ___m_Buffer;
	int32_t ___m_Length;
	int32_t ___m_AllocatorLabel;
};
struct ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000 
{
	ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57 
{
	ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA 
{
	ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84 
{
	ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724 
{
	ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085 
{
	ByReference_1_tC71D682DBC538763066DF671429413D25394012A ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7 
{
	ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E 
{
	ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974 
{
	ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44 
{
	ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71 
{
	ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185 
{
	ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB 
{
	ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357 
{
	ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E 
{
	ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5 
{
	ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8 
{
	ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8 
{
	ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_tA850A6C0E88ABBA37646A078ACBC24D6D5FD9B4D 
{
	ByReference_1_t9C85BCCAAF8C525B6C06B07E922D8D217BE8D6FC ____pointer;
	int32_t ____length;
};
struct ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC 
{
	ByReference_1_t607C1F3BC28B0E21B969461CDB0720FB01A82141 ____pointer;
	int32_t ____length;
};
struct SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474 
{
	int32_t ___type;
	int32_t ___uniqueStringId;
};
struct Span_1_t2A675B8E3E38550E93916E5DCA96655003AAF435 
{
	ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 ____pointer;
	int32_t ____length;
};
struct Span_1_t9281853CEBD9A6003A40E179A340A790E331B575 
{
	ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A ____pointer;
	int32_t ____length;
};
struct Span_1_t84CC3492C4F25DC684EB1A4E00493E60CD98D428 
{
	ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 ____pointer;
	int32_t ____length;
};
struct Span_1_t291EAC5144D1F469ED3426F74052EFC6F1E9BCB8 
{
	ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F ____pointer;
	int32_t ____length;
};
struct Span_1_t9ED8A526081AA124D11AF2D755A0B15118AE965A 
{
	ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F ____pointer;
	int32_t ____length;
};
struct Span_1_t9361F6740620C10133091ACD2A48E3B994B1D176 
{
	ByReference_1_tC71D682DBC538763066DF671429413D25394012A ____pointer;
	int32_t ____length;
};
struct Span_1_t093DFA1FE4BCEB341D9AFE57AD01A8FEBF32B4AB 
{
	ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D ____pointer;
	int32_t ____length;
};
struct Span_1_tCF93B7CB319A45CD677BBDFD2A55AD47DF463EB3 
{
	ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD ____pointer;
	int32_t ____length;
};
struct Span_1_t140ED24BBE87C7CE97312D06D5316A9801E31506 
{
	ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 ____pointer;
	int32_t ____length;
};
struct Span_1_tF176F22E2BDE5E54D571766DE8FE21ACFF6CE298 
{
	ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E ____pointer;
	int32_t ____length;
};
struct Span_1_t5AD383DD652E3E6DB3205BDF87EE6BD77466A034 
{
	ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA ____pointer;
	int32_t ____length;
};
struct Span_1_tBF13F9501CCD12FFB2F5A59090DEA7BD31F5BDC7 
{
	ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 ____pointer;
	int32_t ____length;
};
struct Span_1_t5546CD84F181EC350FB506984B90241364B8C8F6 
{
	ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 ____pointer;
	int32_t ____length;
};
struct Span_1_t460BF9A574BE0955E6E375F5EDC0E0830FA47381 
{
	ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 ____pointer;
	int32_t ____length;
};
struct Span_1_t9DA7921D616AFD6EFF2CEF642A21C62ED20C6F05 
{
	ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 ____pointer;
	int32_t ____length;
};
struct Span_1_t83DEC692D54FF8BED9317442919944F109D8D9FB 
{
	ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 ____pointer;
	int32_t ____length;
};
struct Span_1_t6BF1EBB3CB6E0BEE5E6E144F0324DFB047F18F32 
{
	ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 ____pointer;
	int32_t ____length;
};
struct Span_1_t399B9EFF21D03E62E3B6A8591A5B91D4B44A6649 
{
	ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 ____pointer;
	int32_t ____length;
};
struct Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305 
{
	ByReference_1_t9C85BCCAAF8C525B6C06B07E922D8D217BE8D6FC ____pointer;
	int32_t ____length;
};
struct Span_1_tDEB40BEFA77B5E4BB49B058CD3050EEA4DD36C54 
{
	ByReference_1_t607C1F3BC28B0E21B969461CDB0720FB01A82141 ____pointer;
	int32_t ____length;
};
struct SystemException_tCC48D868298F4C0705279823E34B00F4FBDB7295  : public Exception_t
{
};
struct Type_t  : public MemberInfo_t
{
	RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B ____impl;
};
struct AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D 
{
	String_t* ___m_Path;
	String_t* ___m_TypeFullName;
	LazyLoadReference_1_tD57A582D5A28F3AE34FBB810985EF171325FAF1B ___m_AssetReference;
	EntityId_t982FBD037EAC5CA077B1602A7EA40E3523AA0FC8 ___m_EntityId;
	Type_t* ___m_CachedType;
};
struct AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D_marshaled_pinvoke
{
	char* ___m_Path;
	char* ___m_TypeFullName;
	LazyLoadReference_1_tD57A582D5A28F3AE34FBB810985EF171325FAF1B ___m_AssetReference;
	EntityId_t982FBD037EAC5CA077B1602A7EA40E3523AA0FC8 ___m_EntityId;
	Type_t* ___m_CachedType;
};
struct AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D_marshaled_com
{
	Il2CppChar* ___m_Path;
	Il2CppChar* ___m_TypeFullName;
	LazyLoadReference_1_tD57A582D5A28F3AE34FBB810985EF171325FAF1B ___m_AssetReference;
	EntityId_t982FBD037EAC5CA077B1602A7EA40E3523AA0FC8 ___m_EntityId;
	Type_t* ___m_CachedType;
};
struct PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F 
{
	String_t* ___name;
	int32_t ___type;
	ResourceIdLists_tD6328DF3B43DB6A2B045464122D4DD5AC1629D99* ___resourceReadLists;
	ResourceIdLists_tD6328DF3B43DB6A2B045464122D4DD5AC1629D99* ___resourceWriteLists;
	bool ___culled;
	bool ___async;
	int32_t ___nativeSubPassIndex;
	int32_t ___syncToPassIndex;
	int32_t ___syncFromPassIndex;
	bool ___generateDebugData;
	NRPInfo_tFAE346DBF564B1FDA1EBC1D2F0C3EDC93143D04F* ___nrpInfo;
	PassScriptInfo_t8619301849E12A8422C5C4BF3D19F5D7410A0A31 ___scriptInfo;
};
struct PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F_marshaled_pinvoke
{
	char* ___name;
	int32_t ___type;
	ResourceIdLists_tD6328DF3B43DB6A2B045464122D4DD5AC1629D99* ___resourceReadLists;
	ResourceIdLists_tD6328DF3B43DB6A2B045464122D4DD5AC1629D99* ___resourceWriteLists;
	int32_t ___culled;
	int32_t ___async;
	int32_t ___nativeSubPassIndex;
	int32_t ___syncToPassIndex;
	int32_t ___syncFromPassIndex;
	int32_t ___generateDebugData;
	NRPInfo_tFAE346DBF564B1FDA1EBC1D2F0C3EDC93143D04F* ___nrpInfo;
	PassScriptInfo_t8619301849E12A8422C5C4BF3D19F5D7410A0A31_marshaled_pinvoke ___scriptInfo;
};
struct PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F_marshaled_com
{
	Il2CppChar* ___name;
	int32_t ___type;
	ResourceIdLists_tD6328DF3B43DB6A2B045464122D4DD5AC1629D99* ___resourceReadLists;
	ResourceIdLists_tD6328DF3B43DB6A2B045464122D4DD5AC1629D99* ___resourceWriteLists;
	int32_t ___culled;
	int32_t ___async;
	int32_t ___nativeSubPassIndex;
	int32_t ___syncToPassIndex;
	int32_t ___syncFromPassIndex;
	int32_t ___generateDebugData;
	NRPInfo_tFAE346DBF564B1FDA1EBC1D2F0C3EDC93143D04F* ___nrpInfo;
	PassScriptInfo_t8619301849E12A8422C5C4BF3D19F5D7410A0A31_marshaled_com ___scriptInfo;
};
struct EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 
{
	RenderData_t1ABE116B2B5E0409AC699E195922516606531DC2* ___renderData;
	int32_t ___type;
	Entry_t475ED76E31923970E7F7A6522E570E7577C487B9* ___rootEntry;
};
struct EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289_marshaled_pinvoke
{
	RenderData_t1ABE116B2B5E0409AC699E195922516606531DC2* ___renderData;
	int32_t ___type;
	Entry_t475ED76E31923970E7F7A6522E570E7577C487B9* ___rootEntry;
};
struct EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289_marshaled_com
{
	RenderData_t1ABE116B2B5E0409AC699E195922516606531DC2* ___renderData;
	int32_t ___type;
	Entry_t475ED76E31923970E7F7A6522E570E7577C487B9* ___rootEntry;
};
struct EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96 
{
	FixedList32Bytes_1_t02D797FE0EF11E83016BA95DD7B282490C8A472E ___m_FixedArray;
	UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B ___m_List;
	int32_t ___m_Length;
	bool ___m_Created;
	bool ___m_IsEmbedded;
};
struct ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263  : public SystemException_tCC48D868298F4C0705279823E34B00F4FBDB7295
{
	String_t* ____paramName;
};
struct ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1  : public SystemException_tCC48D868298F4C0705279823E34B00F4FBDB7295
{
};
struct NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A  : public SystemException_tCC48D868298F4C0705279823E34B00F4FBDB7295
{
};
struct ArgumentNullException_t327031E412FAB2351B0022DD5DAD47E67E597129  : public ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263
{
};
struct ArgumentOutOfRangeException_tEA2822DAF62B10EEED00E0E3A341D4BAF78CF85F  : public ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263
{
	RuntimeObject* ____actualValue;
};
struct EmptyArray_1_tBCCAE4080E81992F81CEC3B682CED9E81A3B4D67_StaticFields
{
	EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA* ___Value;
};
struct EmptyArray_1_tF44AD9BD1A58C47BDCB13A8D4D22873C785CC3F8_StaticFields
{
	HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* ___Value;
};
struct EmptyArray_1_t4505232400AEC5D181E96238357D9ACD1C992762_StaticFields
{
	NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0* ___Value;
};
struct EmptyArray_1_t0542F0EB5C43D54C8F4ADCAB1E94F18AEA151867_StaticFields
{
	SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06* ___Value;
};
struct EmptyArray_1_tC9589F12F2382131419143780EC4B16F75839727_StaticFields
{
	UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C* ___Value;
};
struct EmptyArray_1_t39CC4801B12BC59D744D8F2F14920ED998228BE1_StaticFields
{
	UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A* ___Value;
};
struct EmptyArray_1_t8F16BED9A16610B0610D3B8977C56192C7CE8275_StaticFields
{
	UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B* ___Value;
};
struct EmptyArray_1_tE873052363E5FFF3E3324D48BF2E70EABF9FBA3E_StaticFields
{
	UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC* ___Value;
};
struct EmptyArray_1_tE694D0227F619BC5A10811AC94E5B6D8EE0CBD57_StaticFields
{
	UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1* ___Value;
};
struct EmptyArray_1_tA05DBCB91EE064FE54203B7543F218C61D4C292D_StaticFields
{
	UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3* ___Value;
};
struct EmptyArray_1_tFEE1A4E0C8058B54F07835CFB63F231873095076_StaticFields
{
	UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6* ___Value;
};
struct EmptyArray_1_t8505E6935DD4C58400550971BB8321BD8CE9D6CF_StaticFields
{
	UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8* ___Value;
};
struct EmptyArray_1_tA0B73630739AC85F81DDEFE547CAFB1C84FB72C6_StaticFields
{
	UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6* ___Value;
};
struct EmptyArray_1_t1347A16AC3E72AFF909DAA98EED1FA11A4470068_StaticFields
{
	UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD* ___Value;
};
struct EmptyArray_1_t5058CECA8099AD79767245351D26A5CB48C84746_StaticFields
{
	UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00* ___Value;
};
struct EmptyArray_1_t47AB7FAF9E162BBE81FCF7964F3209ECF415B0A4_StaticFields
{
	UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB* ___Value;
};
struct EmptyArray_1_t410AE8CFE5DA7B6BD5DA6669225E54549802E603_StaticFields
{
	UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06* ___Value;
};
struct EmptyArray_1_t15EC9BF1140A58A19136B22B04EFD7559BBCC2D4_StaticFields
{
	UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B* ___Value;
};
struct String_t_StaticFields
{
	String_t* ___Empty;
};
struct Boolean_t09A6377A54BE2F9E6985A8149F19234FD7DDFE22_StaticFields
{
	String_t* ___TrueString;
	String_t* ___FalseString;
};
struct Char_t521A6F19B456D956AF452D926C32709DC03D6B17_StaticFields
{
	ByteU5BU5D_tA6237BF417AE52AD70CFB4EF24A7A82613DF9031* ___s_categoryForLatin1;
};
struct IntPtr_t_StaticFields
{
	intptr_t ___Zero;
};
struct UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484_StaticFields
{
	RuntimeObject* ___comparer;
};
struct Type_t_StaticFields
{
	Binder_t91BFCE95A7057FADF4D8A1A342AFE52872246235* ___s_defaultBinder;
	Il2CppChar ___Delimiter;
	TypeU5BU5D_t97234E1129B564EB38B8D85CAC2AD8B5B9522FFB* ___EmptyTypes;
	RuntimeObject* ___Missing;
	MemberFilter_tF644F1AE82F611B677CE1964D5A3277DDA21D553* ___FilterAttribute;
	MemberFilter_tF644F1AE82F611B677CE1964D5A3277DDA21D553* ___FilterName;
	MemberFilter_tF644F1AE82F611B677CE1964D5A3277DDA21D553* ___FilterNameIgnoreCase;
};
#ifdef __clang__
#pragma clang diagnostic pop
#endif
struct TextureInfoU5BU5D_t0571178EAC2A0DE9A1F27F2C00A9301E04AAFB83  : public RuntimeArray
{
	ALIGN_FIELD (8) TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B m_Items[1];

	inline TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___texture), (void*)NULL);
	}
	inline TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___texture), (void*)NULL);
	}
};
struct ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918  : public RuntimeArray
{
	ALIGN_FIELD (8) RuntimeObject* m_Items[1];

	inline RuntimeObject* GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline RuntimeObject** GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, RuntimeObject* value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)m_Items + index, (void*)value);
	}
	inline RuntimeObject* GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline RuntimeObject** GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, RuntimeObject* value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)m_Items + index, (void*)value);
	}
};
struct RaycastHitDataU5BU5D_t98BBA3CE354036B88621172C27ED5C5DD7CB9279  : public RuntimeArray
{
	ALIGN_FIELD (8) RaycastHitData_t5EAB266730389AB27715962670C2512800451841 m_Items[1];

	inline RaycastHitData_t5EAB266730389AB27715962670C2512800451841 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline RaycastHitData_t5EAB266730389AB27715962670C2512800451841* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, RaycastHitData_t5EAB266730389AB27715962670C2512800451841 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___U3CgraphicU3Ek__BackingField), (void*)NULL);
	}
	inline RaycastHitData_t5EAB266730389AB27715962670C2512800451841 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline RaycastHitData_t5EAB266730389AB27715962670C2512800451841* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, RaycastHitData_t5EAB266730389AB27715962670C2512800451841 value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___U3CgraphicU3Ek__BackingField), (void*)NULL);
	}
};
struct WorkRequestU5BU5D_t1B912B8BE58CF60CAF3A4FEC0A5C0F5BB6D99577  : public RuntimeArray
{
	ALIGN_FIELD (8) WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 m_Items[1];

	inline WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___m_DelagateCallback), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___m_DelagateState), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___m_WaitHandle), (void*)NULL);
		#endif
	}
	inline WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___m_DelagateCallback), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___m_DelagateState), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___m_WaitHandle), (void*)NULL);
		#endif
	}
};
struct AssetEntryU5BU5D_t83ECF66F13D78425A1AF86967D10F3FA0A0C123F  : public RuntimeArray
{
	ALIGN_FIELD (8) AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D m_Items[1];

	inline AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___m_Path), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___m_TypeFullName), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___m_CachedType), (void*)NULL);
		#endif
	}
	inline AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___m_Path), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___m_TypeFullName), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___m_CachedType), (void*)NULL);
		#endif
	}
};
struct SlotDefinitionU5BU5D_t9003D04EBDD74C44DD8490A99624A727154E1299  : public RuntimeArray
{
	ALIGN_FIELD (8) SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 m_Items[1];

	inline SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___name), (void*)NULL);
	}
	inline SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___name), (void*)NULL);
	}
};
struct SlotUsageEntryU5BU5D_t02CCAC4881F115443BE39FCBE8439A9DCFC1C67A  : public RuntimeArray
{
	ALIGN_FIELD (8) SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 m_Items[1];

	inline SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___slotName), (void*)NULL);
	}
	inline SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___slotName), (void*)NULL);
	}
};
struct UsingEntryU5BU5D_t3E321CB1464DE1D2F7FDE3790BD4AD8B72FBE811  : public RuntimeArray
{
	ALIGN_FIELD (8) UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 m_Items[1];

	inline UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___alias), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___path), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___asset), (void*)NULL);
		#endif
	}
	inline UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___alias), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___path), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___asset), (void*)NULL);
		#endif
	}
};
struct VersionInfoU5BU5D_tA86713FC86D1EDA523BC741A17D81B20A869AE64  : public RuntimeArray
{
	ALIGN_FIELD (8) VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 m_Items[1];

	inline VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___source), (void*)NULL);
	}
	inline VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___source), (void*)NULL);
	}
};
struct XmlSchemaObjectEntryU5BU5D_tBCEE5881A0EF3ACBC998EFA679ACBF1ED8256E27  : public RuntimeArray
{
	ALIGN_FIELD (8) XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD m_Items[1];

	inline XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___qname), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___xso), (void*)NULL);
		#endif
	}
	inline XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___qname), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___xso), (void*)NULL);
		#endif
	}
};
struct VolumeParameterChainU5BU5D_t0474622D9FD8B1CC198D56824468949D1E1C680F  : public RuntimeArray
{
	ALIGN_FIELD (8) VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E m_Items[1];

	inline VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((&((m_Items + index)->___nameAndTooltip))->___name), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((&((m_Items + index)->___nameAndTooltip))->___tooltip), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___volumeProfile), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___volumeComponent), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___volume), (void*)NULL);
		#endif
	}
	inline VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((&((m_Items + index)->___nameAndTooltip))->___name), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((&((m_Items + index)->___nameAndTooltip))->___tooltip), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___volumeProfile), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___volumeComponent), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___volume), (void*)NULL);
		#endif
	}
};
struct ContextMenuItemU5BU5D_tFD4FC81929646BCD206377E2AC8E290E93FEE279  : public RuntimeArray
{
	ALIGN_FIELD (8) ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 m_Items[1];

	inline ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___displayName), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___action), (void*)NULL);
		#endif
	}
	inline ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___displayName), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___action), (void*)NULL);
		#endif
	}
};
struct LayoutMatcherU5BU5D_t790C71C3787F12C3EE9F7ABDC24DFCEB5281F90E  : public RuntimeArray
{
	ALIGN_FIELD (8) LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 m_Items[1];

	inline LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((&((m_Items + index)->___layoutName))->___m_StringOriginalCase), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((&((m_Items + index)->___layoutName))->___m_StringLowerCase), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((&((m_Items + index)->___deviceMatcher))->___m_Patterns), (void*)NULL);
		#endif
	}
	inline LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((&((m_Items + index)->___layoutName))->___m_StringOriginalCase), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((&((m_Items + index)->___layoutName))->___m_StringLowerCase), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((&((m_Items + index)->___deviceMatcher))->___m_Patterns), (void*)NULL);
		#endif
	}
};
struct InstructionViewU5BU5D_t2A200DCB627CD67C1DDBD22595A355894F2646A3  : public RuntimeArray
{
	ALIGN_FIELD (8) InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D m_Items[1];

	inline InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->____name), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->____instruction), (void*)NULL);
		#endif
	}
	inline InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->____name), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->____instruction), (void*)NULL);
		#endif
	}
};
struct PassDataU5BU5D_tF21A03049926F4AE1289DBF568C76ED64042A9FC  : public RuntimeArray
{
	ALIGN_FIELD (8) PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F m_Items[1];

	inline PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___name), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___resourceReadLists), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___resourceWriteLists), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___nrpInfo), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((&((m_Items + index)->___scriptInfo))->___filePath), (void*)NULL);
		#endif
	}
	inline PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___name), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___resourceReadLists), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___resourceWriteLists), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___nrpInfo), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((&((m_Items + index)->___scriptInfo))->___filePath), (void*)NULL);
		#endif
	}
};
struct ResourceDataU5BU5D_t7EB547044DA870E25BACFEDEFCCD7821FE72022B  : public RuntimeArray
{
	ALIGN_FIELD (8) ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 m_Items[1];

	inline ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___name), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___consumerList), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___producerList), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___textureData), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___bufferData), (void*)NULL);
		#endif
	}
	inline ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___name), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___consumerList), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___producerList), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___textureData), (void*)NULL);
		#endif
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___bufferData), (void*)NULL);
		#endif
	}
};
struct EntryProcessingInfoU5BU5D_tAB0CBF4A4379F39BA667FBBFCB22E4174C4D319B  : public RuntimeArray
{
	ALIGN_FIELD (8) EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 m_Items[1];

	inline EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___renderData), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___rootEntry), (void*)NULL);
		#endif
	}
	inline EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___renderData), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___rootEntry), (void*)NULL);
		#endif
	}
};
struct PassCompatibilityInfoU5BU5D_t7B46D72837B465DBE4D623FD609B34DE43FE3317  : public RuntimeArray
{
	ALIGN_FIELD (8) PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 m_Items[1];

	inline PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___message), (void*)NULL);
	}
	inline PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___message), (void*)NULL);
	}
};
struct KeyValuePair_2U5BU5D_t885F2E060B0261B18E97D336746D53BA61338F57  : public RuntimeArray
{
	ALIGN_FIELD (8) uint8_t m_Items[1];

	inline uint8_t* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + il2cpp_array_calc_byte_offset(this, index);
	}
	inline uint8_t* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + il2cpp_array_calc_byte_offset(this, index);
	}
};
struct DictionaryEntryU5BU5D_t410156653E754D17B5E1161CC6CF565103B63533  : public RuntimeArray
{
	ALIGN_FIELD (8) DictionaryEntry_t171080F37B311C25AA9E75888F9C9D703FA721BB m_Items[1];

	inline DictionaryEntry_t171080F37B311C25AA9E75888F9C9D703FA721BB GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline DictionaryEntry_t171080F37B311C25AA9E75888F9C9D703FA721BB* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, DictionaryEntry_t171080F37B311C25AA9E75888F9C9D703FA721BB value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->____key), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->____value), (void*)NULL);
		#endif
	}
	inline DictionaryEntry_t171080F37B311C25AA9E75888F9C9D703FA721BB GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline DictionaryEntry_t171080F37B311C25AA9E75888F9C9D703FA721BB* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, DictionaryEntry_t171080F37B311C25AA9E75888F9C9D703FA721BB value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->____key), (void*)NULL);
		#if IL2CPP_ENABLE_STRICT_WRITE_BARRIERS
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->____value), (void*)NULL);
		#endif
	}
};
struct ByteU5BU5D_tA6237BF417AE52AD70CFB4EF24A7A82613DF9031  : public RuntimeArray
{
	ALIGN_FIELD (8) uint8_t m_Items[1];

	inline uint8_t GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline uint8_t* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, uint8_t value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline uint8_t GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline uint8_t* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, uint8_t value)
	{
		m_Items[index] = value;
	}
};
struct __Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC  : public RuntimeArray
{
	ALIGN_FIELD (8) uint8_t m_Items[1];

	inline uint8_t* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + il2cpp_array_calc_byte_offset(this, index);
	}
	inline uint8_t* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + il2cpp_array_calc_byte_offset(this, index);
	}
};
struct EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA  : public RuntimeArray
{
	ALIGN_FIELD (8) EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96 m_Items[1];

	inline EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96 value)
	{
		m_Items[index] = value;
	}
};
struct HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5  : public RuntimeArray
{
	ALIGN_FIELD (8) HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5 m_Items[1];

	inline HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___compiledGraph), (void*)NULL);
	}
	inline HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5 value)
	{
		m_Items[index] = value;
		Il2CppCodeGenWriteBarrier((void**)&((m_Items + index)->___compiledGraph), (void*)NULL);
	}
};
struct NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0  : public RuntimeArray
{
	ALIGN_FIELD (8) NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62 m_Items[1];

	inline NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62 value)
	{
		m_Items[index] = value;
	}
};
struct SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06  : public RuntimeArray
{
	ALIGN_FIELD (8) SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474 m_Items[1];

	inline SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474 value)
	{
		m_Items[index] = value;
	}
};
struct UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C  : public RuntimeArray
{
	ALIGN_FIELD (8) UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD m_Items[1];

	inline UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD value)
	{
		m_Items[index] = value;
	}
};
struct UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A  : public RuntimeArray
{
	ALIGN_FIELD (8) UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D m_Items[1];

	inline UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D value)
	{
		m_Items[index] = value;
	}
};
struct UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B  : public RuntimeArray
{
	ALIGN_FIELD (8) UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692 m_Items[1];

	inline UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692 value)
	{
		m_Items[index] = value;
	}
};
struct UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC  : public RuntimeArray
{
	ALIGN_FIELD (8) UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B m_Items[1];

	inline UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B value)
	{
		m_Items[index] = value;
	}
};
struct UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1  : public RuntimeArray
{
	ALIGN_FIELD (8) UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0 m_Items[1];

	inline UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0 value)
	{
		m_Items[index] = value;
	}
};
struct UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3  : public RuntimeArray
{
	ALIGN_FIELD (8) UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718 m_Items[1];

	inline UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718 value)
	{
		m_Items[index] = value;
	}
};
struct UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6  : public RuntimeArray
{
	ALIGN_FIELD (8) UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF m_Items[1];

	inline UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF value)
	{
		m_Items[index] = value;
	}
};
struct UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8  : public RuntimeArray
{
	ALIGN_FIELD (8) UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6 m_Items[1];

	inline UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6 value)
	{
		m_Items[index] = value;
	}
};
struct UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6  : public RuntimeArray
{
	ALIGN_FIELD (8) UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4 m_Items[1];

	inline UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4 value)
	{
		m_Items[index] = value;
	}
};
struct UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD  : public RuntimeArray
{
	ALIGN_FIELD (8) UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A m_Items[1];

	inline UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A value)
	{
		m_Items[index] = value;
	}
};
struct UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00  : public RuntimeArray
{
	ALIGN_FIELD (8) UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73 m_Items[1];

	inline UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73 value)
	{
		m_Items[index] = value;
	}
};
struct UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB  : public RuntimeArray
{
	ALIGN_FIELD (8) UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516 m_Items[1];

	inline UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516 value)
	{
		m_Items[index] = value;
	}
};
struct UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06  : public RuntimeArray
{
	ALIGN_FIELD (8) UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB m_Items[1];

	inline UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB value)
	{
		m_Items[index] = value;
	}
};
struct UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B  : public RuntimeArray
{
	ALIGN_FIELD (8) UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8 m_Items[1];

	inline UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8 GetAt(il2cpp_array_size_t index) const
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items[index];
	}
	inline UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* GetAddressAt(il2cpp_array_size_t index)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		return m_Items + index;
	}
	inline void SetAt(il2cpp_array_size_t index, UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8 value)
	{
		IL2CPP_ARRAY_BOUNDS_CHECK(index, (uint32_t)(this)->max_length);
		m_Items[index] = value;
	}
	inline UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8 GetAtUnchecked(il2cpp_array_size_t index) const
	{
		return m_Items[index];
	}
	inline UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* GetAddressAtUnchecked(il2cpp_array_size_t index)
	{
		return m_Items + index;
	}
	inline void SetAtUnchecked(il2cpp_array_size_t index, UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8 value)
	{
		m_Items[index] = value;
	}
};


IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_mA3718CBDAD334D0C3B3B3D9C2FBFFC64CB9C1280 (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mD22DEE1877768FD46CF1D7BE9E64A9BBF4762858 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m226D99000078C09F61A5D23C9D572EEFD2C1F3AB (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m38FC28A8D172A809848EBBE17B7593C9A4AC5309 (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m0AFB680989F7183252C477DD7EB9EF59D9C88ECC (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m052B85911C70FD4FE70D220FF791FAF6C6479F83 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m37A8647602E0715AC27FDFF43DABCCEF7701AEAB (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, RaycastHitData_t5EAB266730389AB27715962670C2512800451841 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mE1ABD3A991704C640186283F3DD505E3B9A77BB6 (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, RaycastHitData_t5EAB266730389AB27715962670C2512800451841 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m409F5776BEB430BE72273C433CC1850CD93700A7 (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m297F49BCB3FD33C8DE274BA917FFF7B708758DB7 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mDF174A6917D3D93C8D7910C91080D253891A1AC5 (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mC7204EA734A903659BFE12EFC2FD358391419441 (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m31B5E7F8E3D51CB370BE05608F7B2C3C11EE0C55 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m496DFF37E9CC6DE59F0E2B4E2A5DBEAA32DEAD94 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m6057F27D1ACAA9CBF4A9FFC87FDAA2ACC117A809 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mD865206564138ED88C746288B0A9A6EB96555FC2 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m15D679310A0AC97586C8124180F5EB3E1D40A2BC (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m948DB26D5A8A2DF64E9700A6DEB6F836B10749A3 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m9ADA09E692C504A400AF0D8E4BF59A7C3C2C8F93 (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m942BE9C1C9D8A0392F495981442E058E887308CF (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m299B4E260E97612F6BFD1965863F5EDB0D80889F (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mBF48FC95A670E75A65647A9F7520AEB9AE4A0FE6 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m705B2717517A6E1493976E0F972CEC791692FF97 (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mBE061D69DECDF68D566C15E465E25ECFCE11FCD3 (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m05F05C64F32981A1BF2CEC3E7589604A188B612B (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mBA2972FFD773AA00EC4BAD22D43C97C5FFFD31EA (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mD887308D8602D0A6C687F8B588F772CB0D0911A2 (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mCC0B8F0541328E20D9E516ACE2AF53B44AA502ED (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_mCB408C9C0EF8BB4EAF3BD9D74210EA1BF645DF9F (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mCB5B8ABED8FAA81E9313462E91E846577DBF79E7 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mA07C916646443F7E600B771BA5B6E3276CF6F38D (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m24635AF1EE0DBE26C00D1E919C331F3EC3514442 (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_mCB4FF2AFAA94D01923F9242ACB66F817F7CF18C7 (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mC5B4A17FCA21C2DF1F66767E828535AD34B90513 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m116AE421F0EB30927F6725D62792FFA5A6065627 (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mF523F5C22B1C3DFB9577177B1C50F9DC3B9704C2 (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m8458978F11950358DAF515D9793F94E96E164867 (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m0F15E0EC055DA3F521E73184206A61A28D6E1C0F (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mE296E176CF781CFBEDEA890CD7B7438707C5CBC2 (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m25AC6AFADC9DA3C7616FB3DF2538489069FE82FF (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_mCFEB25EF1344B976A050CB6937362A3F5DF0199A (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m3A0010FDAC2908AF80DDEB4BA4458869F0FE9F8F (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m3CAC4C8BA133B39A5BA9FA0A1E0E711E09BD7694 (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mE8080B23EA1AD670E7D7D77D172A6973A222ED2C (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m88DC99D667337D16893CDF63694D22FEAF331E05 (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m9E692C71C0193F22ACD65EEFBA4ECA75E5C53AAD (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m9FE5CCC2B059229D4C97248D4F5E82C20ECB5FBE (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m093DAAF13F65B6DE09B24D00F36FCC13F61E6E15 (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m283266AC4D77DC2424BDBD9CB125A1A61AB55E1C (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mD7979063F69DBCBBA075F88868B40DE92ED347FC (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m7535255C244884FCE69E71A597A10D82C38A21AB (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m07CEF5EB192EFDA22EC079165EEE0F82A03E5FD7 (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m818A3E47FE33091DD1275D2DFDF70695E715E185 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m9E090EF8DAC5EB1362F55C11AC2FD29FE307A954 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m3006B42AEF364FAED734490926CA034ED5348569 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m4D42E127F9A2F6A6D223785F8CA656A4930B87C2 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m0730B9BAC8092A41B1C48042F79C306FD18E553F (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m718A868545EA0ABD0015911A27C3815E8A95752D (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mD6916963F70388076B4D8A005C8C1AC7DB630642 (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mEAC3EE66A5CB94BE471210EA64A682C55D8463D0 (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m8B2AEA509E07E389B797D3576C0DDF9A5551E3A4 (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mC9A90AF46B6E7EC8BC710283B87EB110801FAB1B (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mD750C5DD43B49E3369FF1CC3778B43D83F58636E (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mDA0A610D1FE508DC17DABD5A4D5D861295857416 (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m5BD62585103C935CC4B20021B610D1D480BE6F19 (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mC38E543F0BA4C1931B8FDCDA225802CE37FBD971 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mC061A8BAB0855DF9F3365468CFE7C6897B27DB66 (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m91DD8D51560F4B4A6690B2B4DCF114816973A693 (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void DictionaryEnumerator__ctor_mA1A62AF5ED8AB1B514BBAAAEA9BB3D081C3AA4ED_fshared (DictionaryEnumerator_tA07B53C91CCF243B3DDF48825CD4F71A6835CD77* __this, RuntimeObject* ___0_dictionary, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void KeyValuePair_2__ctor_mD82E516936D2BDE6D46C8C45270250647986231E_fshared (KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669* __this, Il2CppFullySharedGenericAny ___0_key, Il2CppFullySharedGenericAny ___1_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlyMemory_1_ToString_m0C4DF727B39C613F84AC56D6FDAF7ACFF9E39720 (ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399* __this, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305 Span_1_Slice_m9D8BA8245B8DC9BFB4A4164759CBAAEAD1318CD6_inline (Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC Span_1_op_Implicit_m704A5B9FD25EEA23756181A8EB40B875387A6C01_fshared (Span_1_tDEB40BEFA77B5E4BB49B058CD3050EEA4DD36C54 ___0_span, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m7B5C2765879EA5E8D1617D834CC465A39540A913_inline (ReadOnlySpan_1_tA850A6C0E88ABBA37646A078ACBC24D6D5FD9B4D* __this, ByteU5BU5D_tA6237BF417AE52AD70CFB4EF24A7A82613DF9031* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyMemory_1_Equals_mF7DA75997B4FFDFB2D6F953E8DC580EC3C941A61_fshared (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4 ___0_other, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4 Memory_1_op_Implicit_m7216145178505C2CB2BA0E21CB95773BE1E6A7AF_fshared (Memory_1_t762D61B435521D1706EEDC25CA8C8EA1AE19AFEA ___0_memory, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyMemory_1_Equals_mD0C4947B91FD3864C476B6CA8BA929A6F5B01175 (ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyMemory_1_CombineHashCodes_mC20EA69C2706DE824529A0506BD45837E26C6980 (int32_t ___0_h1, int32_t ___1_h2, int32_t ___2_h3, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyMemory_1_GetHashCode_mE47597BBDBFFBC9185DE65261A7388207854ADE6 (ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyMemory_1_CombineHashCodes_m74D5DE9AF0CCB1FF7B88058328C835DBD981C568_fshared (int32_t ___0_left, int32_t ___1_right, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_m04AD05E39D10A41E67653C41A22108A810CA9857_fshared (ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlyMemory_1_ToString_m1AB8B8725FFC7144748E59C73875E2C6822E2321_fshared (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline (ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC* __this, Il2CppFullySharedGenericAny* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mC9869776ABBFE9D2520512EEB39ABD1CFFE7F7B9_fshared_inline (ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC* __this, __Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyMemory_1_Equals_m2C16DF2AE78D8E7182CFAE8E3E07C3B20A777888_fshared (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyMemory_1_GetHashCode_m96535F6C6512A16E6DBC2A8341F8FECDF2E47F54_fshared (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR int32_t Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline (Span_1_tDEB40BEFA77B5E4BB49B058CD3050EEA4DD36C54* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisEmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96_mE391F759232A81F0432F80E844CBA7DDB1004880 (EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* ___0_destination, EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA* Array_Empty_TisEmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96_mD229BDA583D562BD2A433878A338C82536F745F3_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared (ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC ___0_left, ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC ___1_right, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisHashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5_mA8D04698C609F68E916C276ADC1E40C0EDB95A05_gshared (HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* ___0_destination, HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* Array_Empty_TisHashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5_m7546ECBE8AAEBE56E0F447E66B1A47851A568FCC_gshared_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisNativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62_m6931525DB5EBBF296FB06571C6E6FBD595137197 (NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* ___0_destination, NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0* Array_Empty_TisNativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62_mBDB8DDE2D2948EDF2432FC77141B7D1360CDA732_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisSelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474_m8B225EBD79F98163072E7428252E4FDAFE5A3E1A (SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* ___0_destination, SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06* Array_Empty_TisSelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474_m4433599FD227186796BAB47DC5BED2AF106ED67E_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD_mC690AEF1F47ED7A260D15E587C4C342E207B8C32 (UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* ___0_destination, UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C* Array_Empty_TisUnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD_m14FA981EC22CA08E194019E3506AD1ABB6322E6D_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D_m5753FD640BD432A226561D50E1F14CBEEFFFB9B2 (UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* ___0_destination, UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A* Array_Empty_TisUnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D_mB80BD27875E5AD9B06C08FC9D673F81494E06C0D_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692_mC45CF9E0F2492C756D55FAAD0F34035EAC00922D (UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* ___0_destination, UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B* Array_Empty_TisUnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692_m8225D086EDE4F1EA4A744724F13D762BD6A7FFA2_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B_mEE1B8052EF8A53F69256C0CA82FEBB3DBA8851BD (UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* ___0_destination, UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC* Array_Empty_TisUnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B_mD5A5585240A77F26BE14BF51B1F8B7C2259B0019_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0_mF923EFF1994ED30D7E774A6A60C3E27D9A9CFEB0 (UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* ___0_destination, UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1* Array_Empty_TisUnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0_m81189A63B159A0BC9CF1D06BCB85661915D86FEB_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718_m31B03CF22D0E106887FFB49A9FD2BEC54BEB659C (UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* ___0_destination, UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3* Array_Empty_TisUnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718_m6DEB24EE574A3109DB94AA1CFC7A5BA936F84D38_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF_m531E222DA3CEAB4F838160BE8BF0D076B903940C (UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* ___0_destination, UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6* Array_Empty_TisUnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF_mEEAC43923BAB5402C351329E989F7E5FDBBC0E53_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6_m6B7919683C297F7E18711B5748ED3690747AF645 (UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* ___0_destination, UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8* Array_Empty_TisUnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6_m80635F8F2D3D0383C89E07968014ABC30ABEA62E_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4_m43B235BFDAED5E73065C5516FB27FCE903846724 (UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* ___0_destination, UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6* Array_Empty_TisUnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4_mF9B8EDAC651FA801E8CEE8280E4C2E9E9BC36096_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A_m3D68438A3C5FAE6C4F026A5954BEBC6157069B6E (UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* ___0_destination, UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD* Array_Empty_TisUnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A_m19F4090BD5440974029AFE51BC45A5C37D4D5C77_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73_mBDCCC7D03D4C397E8F32FB955EC547A2FDFA5543 (UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* ___0_destination, UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00* Array_Empty_TisUnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73_m38077BA7106C32737B0A147A292DAA166A65A743_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516_m996D3C06C347B6A640186D2FAC8C066B5DD1AAC2 (UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* ___0_destination, UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB* Array_Empty_TisUnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516_m2559F4EE41A1BC5F7F6D91695D46A1FFB8292C19_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB_m12DF3FA9D7727285D808AAECE8E2786E166C62EC (UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* ___0_destination, UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06* Array_Empty_TisUnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB_m198A5A706220D5563451F5718452BA9A56A72461_inline (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8_mB0F180342B1F4A1D35E400B23C6B7CAF85F63CD2 (UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* ___0_destination, UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B* Array_Empty_TisUnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8_mBB7951BE7C90C20D302AF78E7CD56927C0AE123D_inline (const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR void Span_1__ctor_mBA868F06359701D9950DEB1B10F52F848E9FF6DA_fshared_inline (Span_1_tDEB40BEFA77B5E4BB49B058CD3050EEA4DD36C54* __this, Il2CppFullySharedGenericAny* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method) ;

IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC (int32_t ___0_argument, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA (int32_t ___0_resource, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC (RuntimeArray* __this, int32_t ___0_dimension, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_mA3718CBDAD334D0C3B3B3D9C2FBFFC64CB9C1280 (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR Type_t* Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57 (RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B ___0_handle, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58 (const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mD22DEE1877768FD46CF1D7BE9E64A9BBF4762858 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m226D99000078C09F61A5D23C9D572EEFD2C1F3AB (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m38FC28A8D172A809848EBBE17B7593C9A4AC5309 (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m0AFB680989F7183252C477DD7EB9EF59D9C88ECC (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m052B85911C70FD4FE70D220FF791FAF6C6479F83 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m37A8647602E0715AC27FDFF43DABCCEF7701AEAB (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, RaycastHitData_t5EAB266730389AB27715962670C2512800451841 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mE1ABD3A991704C640186283F3DD505E3B9A77BB6 (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, RaycastHitData_t5EAB266730389AB27715962670C2512800451841 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m409F5776BEB430BE72273C433CC1850CD93700A7 (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m297F49BCB3FD33C8DE274BA917FFF7B708758DB7 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mDF174A6917D3D93C8D7910C91080D253891A1AC5 (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mC7204EA734A903659BFE12EFC2FD358391419441 (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m31B5E7F8E3D51CB370BE05608F7B2C3C11EE0C55 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m496DFF37E9CC6DE59F0E2B4E2A5DBEAA32DEAD94 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m6057F27D1ACAA9CBF4A9FFC87FDAA2ACC117A809 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mD865206564138ED88C746288B0A9A6EB96555FC2 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m15D679310A0AC97586C8124180F5EB3E1D40A2BC (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m948DB26D5A8A2DF64E9700A6DEB6F836B10749A3 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m9ADA09E692C504A400AF0D8E4BF59A7C3C2C8F93 (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m942BE9C1C9D8A0392F495981442E058E887308CF (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m299B4E260E97612F6BFD1965863F5EDB0D80889F (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mBF48FC95A670E75A65647A9F7520AEB9AE4A0FE6 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m705B2717517A6E1493976E0F972CEC791692FF97 (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mBE061D69DECDF68D566C15E465E25ECFCE11FCD3 (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m05F05C64F32981A1BF2CEC3E7589604A188B612B (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mBA2972FFD773AA00EC4BAD22D43C97C5FFFD31EA (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mD887308D8602D0A6C687F8B588F772CB0D0911A2 (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mCC0B8F0541328E20D9E516ACE2AF53B44AA502ED (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_mCB408C9C0EF8BB4EAF3BD9D74210EA1BF645DF9F (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mCB5B8ABED8FAA81E9313462E91E846577DBF79E7 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mA07C916646443F7E600B771BA5B6E3276CF6F38D (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m24635AF1EE0DBE26C00D1E919C331F3EC3514442 (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_mCB4FF2AFAA94D01923F9242ACB66F817F7CF18C7 (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mC5B4A17FCA21C2DF1F66767E828535AD34B90513 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m116AE421F0EB30927F6725D62792FFA5A6065627 (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mF523F5C22B1C3DFB9577177B1C50F9DC3B9704C2 (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m8458978F11950358DAF515D9793F94E96E164867 (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m0F15E0EC055DA3F521E73184206A61A28D6E1C0F (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mE296E176CF781CFBEDEA890CD7B7438707C5CBC2 (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m25AC6AFADC9DA3C7616FB3DF2538489069FE82FF (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_mCFEB25EF1344B976A050CB6937362A3F5DF0199A (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m3A0010FDAC2908AF80DDEB4BA4458869F0FE9F8F (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m3CAC4C8BA133B39A5BA9FA0A1E0E711E09BD7694 (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mE8080B23EA1AD670E7D7D77D172A6973A222ED2C (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m88DC99D667337D16893CDF63694D22FEAF331E05 (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m9E692C71C0193F22ACD65EEFBA4ECA75E5C53AAD (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m9FE5CCC2B059229D4C97248D4F5E82C20ECB5FBE (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m093DAAF13F65B6DE09B24D00F36FCC13F61E6E15 (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m283266AC4D77DC2424BDBD9CB125A1A61AB55E1C (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mD7979063F69DBCBBA075F88868B40DE92ED347FC (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m7535255C244884FCE69E71A597A10D82C38A21AB (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m07CEF5EB192EFDA22EC079165EEE0F82A03E5FD7 (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m818A3E47FE33091DD1275D2DFDF70695E715E185 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m9E090EF8DAC5EB1362F55C11AC2FD29FE307A954 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m3006B42AEF364FAED734490926CA034ED5348569 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m4D42E127F9A2F6A6D223785F8CA656A4930B87C2 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m0730B9BAC8092A41B1C48042F79C306FD18E553F (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m718A868545EA0ABD0015911A27C3815E8A95752D (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mD6916963F70388076B4D8A005C8C1AC7DB630642 (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mEAC3EE66A5CB94BE471210EA64A682C55D8463D0 (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m8B2AEA509E07E389B797D3576C0DDF9A5551E3A4 (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mC9A90AF46B6E7EC8BC710283B87EB110801FAB1B (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mD750C5DD43B49E3369FF1CC3778B43D83F58636E (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mDA0A610D1FE508DC17DABD5A4D5D861295857416 (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m5BD62585103C935CC4B20021B610D1D480BE6F19 (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mC38E543F0BA4C1931B8FDCDA225802CE37FBD971 (RuntimeObject* ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mC061A8BAB0855DF9F3365468CFE7C6897B27DB66 (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m91DD8D51560F4B4A6690B2B4DCF114816973A693 (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 ___0_value, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* __this, String_t* ___0_message, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ArgumentNullException__ctor_m444AE141157E333844FC1A9500224C2F9FD24F4B (ArgumentNullException_t327031E412FAB2351B0022DD5DAD47E67E597129* __this, String_t* ___0_paramName, const RuntimeMethod* method) ;
inline void DictionaryEnumerator__ctor_mA1A62AF5ED8AB1B514BBAAAEA9BB3D081C3AA4ED (DictionaryEnumerator_tA07B53C91CCF243B3DDF48825CD4F71A6835CD77* __this, RuntimeObject* ___0_dictionary, const RuntimeMethod* method)
{
	((  void (*) (DictionaryEnumerator_tA07B53C91CCF243B3DDF48825CD4F71A6835CD77*, RuntimeObject*, const RuntimeMethod*))DictionaryEnumerator__ctor_mA1A62AF5ED8AB1B514BBAAAEA9BB3D081C3AA4ED_fshared)(__this, ___0_dictionary, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ArgumentException__ctor_m026938A67AF9D36BB7ED27F80425D7194B514465 (ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263* __this, String_t* ___0_message, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ArgumentOutOfRangeException__ctor_mE5B2755F0BEA043CACF915D5CE140859EE58FA66 (ArgumentOutOfRangeException_tEA2822DAF62B10EEED00E0E3A341D4BAF78CF85F* __this, String_t* ___0_paramName, String_t* ___1_message, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void DictionaryEntry__ctor_m2768353E53A75C4860E34B37DAF1342120C5D1EA (DictionaryEntry_t171080F37B311C25AA9E75888F9C9D703FA721BB* __this, RuntimeObject* ___0_key, RuntimeObject* ___1_value, const RuntimeMethod* method) ;
inline void KeyValuePair_2__ctor_mD82E516936D2BDE6D46C8C45270250647986231E (KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669* __this, Il2CppFullySharedGenericAny ___0_key, Il2CppFullySharedGenericAny ___1_value, const RuntimeMethod* method)
{
	((  void (*) (KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669*, Il2CppFullySharedGenericAny, Il2CppFullySharedGenericAny, const RuntimeMethod*))KeyValuePair_2__ctor_mD82E516936D2BDE6D46C8C45270250647986231E_fshared)((KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669*)__this, ___0_key, ___1_value, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Object__ctor_mE837C6B9FA8C6D5D109F4B2EC885D79919AC0EA2 (RuntimeObject* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987 (String_t* ___0_format, RuntimeObject* ___1_arg0, RuntimeObject* ___2_arg1, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlyMemory_1_ToString_m0C4DF727B39C613F84AC56D6FDAF7ACFF9E39720 (ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399* __this, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305 Span_1_Slice_m9D8BA8245B8DC9BFB4A4164759CBAAEAD1318CD6_inline (Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) ;
inline ReadOnlySpan_1_tA850A6C0E88ABBA37646A078ACBC24D6D5FD9B4D Span_1_op_Implicit_mD249188242C0C9D3192A31E9F7FA74C683F05B84 (Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305 ___0_span, const RuntimeMethod* method)
{
	return ((  ReadOnlySpan_1_tA850A6C0E88ABBA37646A078ACBC24D6D5FD9B4D (*) (Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305, const RuntimeMethod*))Span_1_op_Implicit_m704A5B9FD25EEA23756181A8EB40B875387A6C01_fshared)(___0_span, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m7B5C2765879EA5E8D1617D834CC465A39540A913_inline (ReadOnlySpan_1_tA850A6C0E88ABBA37646A078ACBC24D6D5FD9B4D* __this, ByteU5BU5D_tA6237BF417AE52AD70CFB4EF24A7A82613DF9031* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) ;
inline bool ReadOnlyMemory_1_Equals_mC3969DE0744A246E0576FEDE51191A0D3F5F69A9 (ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399* __this, ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399 ___0_other, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399*, ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399, const RuntimeMethod*))ReadOnlyMemory_1_Equals_mF7DA75997B4FFDFB2D6F953E8DC580EC3C941A61_fshared)(__this, ___0_other, method);
}
inline ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399 Memory_1_op_Implicit_m7B80A71310A3EA9F99CB1774CAFED254811599CD (Memory_1_tB7CEF4416F5014E364267478CEF016A4AC5C0036 ___0_memory, const RuntimeMethod* method)
{
	return ((  ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399 (*) (Memory_1_tB7CEF4416F5014E364267478CEF016A4AC5C0036, const RuntimeMethod*))Memory_1_op_Implicit_m7216145178505C2CB2BA0E21CB95773BE1E6A7AF_fshared)(___0_memory, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyMemory_1_Equals_mD0C4947B91FD3864C476B6CA8BA929A6F5B01175 (ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t Int32_GetHashCode_m253D60FF7527A483E91004B7A2366F13E225E295 (int32_t* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyMemory_1_CombineHashCodes_mC20EA69C2706DE824529A0506BD45837E26C6980 (int32_t ___0_h1, int32_t ___1_h2, int32_t ___2_h3, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyMemory_1_GetHashCode_mE47597BBDBFFBC9185DE65261A7388207854ADE6 (ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399* __this, const RuntimeMethod* method) ;
inline int32_t ReadOnlyMemory_1_CombineHashCodes_mAD75C6BDDB231C42D8A846F50E2B081E244108DA (int32_t ___0_left, int32_t ___1_right, const RuntimeMethod* method)
{
	return ((  int32_t (*) (int32_t, int32_t, const RuntimeMethod*))ReadOnlyMemory_1_CombineHashCodes_m74D5DE9AF0CCB1FF7B88058328C835DBD981C568_fshared)(___0_left, ___1_right, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56 (const RuntimeMethod* method) ;
inline String_t* ReadOnlySpan_1_ToString_m04AD05E39D10A41E67653C41A22108A810CA9857 (ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC* __this, const RuntimeMethod* method)
{
	return ((  String_t* (*) (ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC*, const RuntimeMethod*))ReadOnlySpan_1_ToString_m04AD05E39D10A41E67653C41A22108A810CA9857_fshared)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* String_Substring_mB1D94F47935D22E130FF2C01DBB6A4135FBB76CE (String_t* __this, int32_t ___0_startIndex, int32_t ___1_length, const RuntimeMethod* method) ;
inline String_t* ReadOnlyMemory_1_ToString_m1AB8B8725FFC7144748E59C73875E2C6822E2321 (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, const RuntimeMethod* method)
{
	return ((  String_t* (*) (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4*, const RuntimeMethod*))ReadOnlyMemory_1_ToString_m1AB8B8725FFC7144748E59C73875E2C6822E2321_fshared)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR Il2CppChar* String_GetRawStringData_m87BC50B7B314C055E27A28032D1003D42FDE411D (String_t* __this, const RuntimeMethod* method) ;
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR int32_t String_get_Length_m42625D67623FA5CC7A44D47425CE86FB946542D2_inline (String_t* __this, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_inline (ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC* __this, Il2CppFullySharedGenericAny* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC*, Il2CppFullySharedGenericAny*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
inline void ReadOnlySpan_1__ctor_mC9869776ABBFE9D2520512EEB39ABD1CFFE7F7B9_inline (ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC* __this, __Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC*, __Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC*, int32_t, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mC9869776ABBFE9D2520512EEB39ABD1CFFE7F7B9_fshared_inline)(__this, ___0_array, ___1_start, ___2_length, method);
}
inline bool ReadOnlyMemory_1_Equals_m2C16DF2AE78D8E7182CFAE8E3E07C3B20A777888 (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4*, RuntimeObject*, const RuntimeMethod*))ReadOnlyMemory_1_Equals_m2C16DF2AE78D8E7182CFAE8E3E07C3B20A777888_fshared)(__this, ___0_obj, method);
}
inline bool ReadOnlyMemory_1_Equals_mF7DA75997B4FFDFB2D6F953E8DC580EC3C941A61 (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4 ___0_other, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4*, ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4, const RuntimeMethod*))ReadOnlyMemory_1_Equals_mF7DA75997B4FFDFB2D6F953E8DC580EC3C941A61_fshared)(__this, ___0_other, method);
}
inline int32_t ReadOnlyMemory_1_GetHashCode_m96535F6C6512A16E6DBC2A8341F8FECDF2E47F54 (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4*, const RuntimeMethod*))ReadOnlyMemory_1_GetHashCode_m96535F6C6512A16E6DBC2A8341F8FECDF2E47F54_fshared)(__this, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR uint8_t* Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline (RuntimeArray* __this, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5 (const RuntimeMethod* method) ;
inline int32_t Span_1_get_Length_mFAB3C81B4C721D97D620490285A98D10429F2C64_inline (Span_1_t2A675B8E3E38550E93916E5DCA96655003AAF435* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t2A675B8E3E38550E93916E5DCA96655003AAF435*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisEmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96_mE391F759232A81F0432F80E844CBA7DDB1004880 (EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* ___0_destination, EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D (const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_m2310FC0E91B7ECFAE542316434BB4C9D6782042B_inline (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000* __this, EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000*, EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA* Array_Empty_TisEmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96_mD229BDA583D562BD2A433878A338C82536F745F3_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_mBDAC100928A2A40355010648140EA50C37DE399E (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000 ___0_left, ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000 ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000, ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ThrowHelper_ThrowInvalidTypeWithPointersNotSupported_m5707DE408588F6EAC3FC7D10F9520308CF8C8CCF (Type_t* ___0_targetType, const RuntimeMethod* method) ;
inline int32_t Span_1_get_Length_m70ECF63AA57B2B62F767D7B9290E6F6FD35B8E9E_inline (Span_1_t9281853CEBD9A6003A40E179A340A790E331B575* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t9281853CEBD9A6003A40E179A340A790E331B575*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
inline void Buffer_Memmove_TisHashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5_mA8D04698C609F68E916C276ADC1E40C0EDB95A05 (HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* ___0_destination, HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method)
{
	((  void (*) (HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5*, HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5*, uint64_t, const RuntimeMethod*))Buffer_Memmove_TisHashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5_mA8D04698C609F68E916C276ADC1E40C0EDB95A05_gshared)(___0_destination, ___1_source, ___2_elementCount, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* String_CreateString_m3F8794FEB452558B8A68C65E1F0B603B3D94E0E2 (String_t* __this, Il2CppChar* ___0_value, int32_t ___1_startIndex, int32_t ___2_length, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_m61A414D4F9636EAC0C3689FCCF1A7EA5ECD32F53_inline (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57* __this, HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57*, HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
inline HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* Array_Empty_TisHashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5_m7546ECBE8AAEBE56E0F447E66B1A47851A568FCC_inline (const RuntimeMethod* method)
{
	return ((  HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* (*) (const RuntimeMethod*))Array_Empty_TisHashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5_m7546ECBE8AAEBE56E0F447E66B1A47851A568FCC_gshared_inline)(method);
}
inline bool ReadOnlySpan_1_op_Equality_m3E5BDB77835A736157FA2EC596A124328094905D (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57 ___0_left, ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57 ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57, ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_mCBA967D766B41C6F7A5A958282339CC12C808833_inline (Span_1_t84CC3492C4F25DC684EB1A4E00493E60CD98D428* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t84CC3492C4F25DC684EB1A4E00493E60CD98D428*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisNativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62_m6931525DB5EBBF296FB06571C6E6FBD595137197 (NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* ___0_destination, NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_mB77B497E05DB783A900DCEAD111F61A3F27C7D35_inline (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA* __this, NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA*, NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0* Array_Empty_TisNativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62_mBDB8DDE2D2948EDF2432FC77141B7D1360CDA732_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_m1C315B0091ADD10B08153159755014876AB3A48B (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA ___0_left, ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA, ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_mBA6FA6140EADE76BD14920BDC6A3E87EDB72FB76_inline (Span_1_t291EAC5144D1F469ED3426F74052EFC6F1E9BCB8* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t291EAC5144D1F469ED3426F74052EFC6F1E9BCB8*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisSelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474_m8B225EBD79F98163072E7428252E4FDAFE5A3E1A (SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* ___0_destination, SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_m68B11A5CBD341B71C3B49A184D9A4A0F68B2BC1B_inline (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84* __this, SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84*, SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06* Array_Empty_TisSelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474_m4433599FD227186796BAB47DC5BED2AF106ED67E_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_m273AE2A699A7739E89673154DA9E3BE6B08A180D (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84 ___0_left, ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84 ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84, ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_mAE734F1E7D866942E70763D9232D006153CC93C8_inline (Span_1_t9ED8A526081AA124D11AF2D755A0B15118AE965A* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t9ED8A526081AA124D11AF2D755A0B15118AE965A*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD_mC690AEF1F47ED7A260D15E587C4C342E207B8C32 (UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* ___0_destination, UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_mE74E20E42241965E7A458DF5E23A7FA9058C4F4E_inline (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724* __this, UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724*, UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C* Array_Empty_TisUnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD_m14FA981EC22CA08E194019E3506AD1ABB6322E6D_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_mF3F15A8AA6E17FA6D014FF4ABE0086AD06B6D198 (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724 ___0_left, ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724 ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724, ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_m757FB90F888A97214E70C7D7DB66DCBB57ED9317_inline (Span_1_t9361F6740620C10133091ACD2A48E3B994B1D176* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t9361F6740620C10133091ACD2A48E3B994B1D176*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D_m5753FD640BD432A226561D50E1F14CBEEFFFB9B2 (UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* ___0_destination, UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_mE51F6529B403BD5E3C8AAE7BAE04BC3F93F7C31F_inline (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085* __this, UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085*, UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A* Array_Empty_TisUnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D_mB80BD27875E5AD9B06C08FC9D673F81494E06C0D_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_mAA0D16E0236C8BED9AB454299585D774E815A4A8 (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085 ___0_left, ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085 ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085, ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_m9A18653FCB90AB3ACEBA696165B559FB2BC04AD7_inline (Span_1_t093DFA1FE4BCEB341D9AFE57AD01A8FEBF32B4AB* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t093DFA1FE4BCEB341D9AFE57AD01A8FEBF32B4AB*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692_mC45CF9E0F2492C756D55FAAD0F34035EAC00922D (UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* ___0_destination, UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_m199E5AF4F96498C11635398C59864ECAB82E7455_inline (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7* __this, UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7*, UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B* Array_Empty_TisUnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692_m8225D086EDE4F1EA4A744724F13D762BD6A7FFA2_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_mBCAD4291296A130D084599C071B39A72441A6041 (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7 ___0_left, ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7 ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7, ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_m64759923EC787AC67D237C126B1F9912A0757B25_inline (Span_1_tCF93B7CB319A45CD677BBDFD2A55AD47DF463EB3* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_tCF93B7CB319A45CD677BBDFD2A55AD47DF463EB3*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B_mEE1B8052EF8A53F69256C0CA82FEBB3DBA8851BD (UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* ___0_destination, UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_m3F71A8FCBA59B8D461F3B6CA8F89B020499102F8_inline (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E* __this, UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E*, UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC* Array_Empty_TisUnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B_mD5A5585240A77F26BE14BF51B1F8B7C2259B0019_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_mE6044990D7E1998FCBA25CBD93EC07FB978178A3 (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E ___0_left, ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E, ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_m25AA5DB60DDFA74CDC6FC67BCE440F807F40C824_inline (Span_1_t140ED24BBE87C7CE97312D06D5316A9801E31506* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t140ED24BBE87C7CE97312D06D5316A9801E31506*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0_mF923EFF1994ED30D7E774A6A60C3E27D9A9CFEB0 (UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* ___0_destination, UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_m0A622A67EF6097E611538708F12B2AFCDBD113A1_inline (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974* __this, UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974*, UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1* Array_Empty_TisUnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0_m81189A63B159A0BC9CF1D06BCB85661915D86FEB_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_mE014CA0F1BF433B90328F47079B9D6A39F491376 (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974 ___0_left, ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974 ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974, ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_mFD0E4725CBEC468524ED6C42354367A9A7359B95_inline (Span_1_tF176F22E2BDE5E54D571766DE8FE21ACFF6CE298* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_tF176F22E2BDE5E54D571766DE8FE21ACFF6CE298*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718_m31B03CF22D0E106887FFB49A9FD2BEC54BEB659C (UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* ___0_destination, UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_mA8962BCDAF15875BAA1631B9B69E1AC9230C568A_inline (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44* __this, UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44*, UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3* Array_Empty_TisUnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718_m6DEB24EE574A3109DB94AA1CFC7A5BA936F84D38_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_m876FCAB5A193A17183A4C1055D7D78BF713D1E18 (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44 ___0_left, ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44 ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44, ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_m796AE228F2062910CC25672EFEBF8E6F196B79BB_inline (Span_1_t5AD383DD652E3E6DB3205BDF87EE6BD77466A034* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t5AD383DD652E3E6DB3205BDF87EE6BD77466A034*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF_m531E222DA3CEAB4F838160BE8BF0D076B903940C (UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* ___0_destination, UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_m66392F19D65D8E37FF8EFFBBA237A8B3CDBD1E3A_inline (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71* __this, UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71*, UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6* Array_Empty_TisUnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF_mEEAC43923BAB5402C351329E989F7E5FDBBC0E53_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_mE483F93046822C9468678DB29F761D3F06FF3C7E (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71 ___0_left, ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71 ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71, ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_mEF91E66E45055A28639FAA49F9338605E2E05F7C_inline (Span_1_tBF13F9501CCD12FFB2F5A59090DEA7BD31F5BDC7* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_tBF13F9501CCD12FFB2F5A59090DEA7BD31F5BDC7*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6_m6B7919683C297F7E18711B5748ED3690747AF645 (UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* ___0_destination, UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_m6C812749CD726114A53FA991ED2B2081E6A42C54_inline (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185* __this, UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185*, UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8* Array_Empty_TisUnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6_m80635F8F2D3D0383C89E07968014ABC30ABEA62E_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_m795ADA90BB856BC321715377F80986612F556D4C (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185 ___0_left, ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185 ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185, ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_mB346D5ACE2098245EF5F8BDB45CD7299937039AA_inline (Span_1_t5546CD84F181EC350FB506984B90241364B8C8F6* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t5546CD84F181EC350FB506984B90241364B8C8F6*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4_m43B235BFDAED5E73065C5516FB27FCE903846724 (UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* ___0_destination, UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_mC0D0EA7EE88DAA315FBD8A84318719AB5E2BAA66_inline (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB* __this, UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB*, UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6* Array_Empty_TisUnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4_mF9B8EDAC651FA801E8CEE8280E4C2E9E9BC36096_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_mD76E07AC17F959B55344C6E355DB9D0CEC31FC0C (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB ___0_left, ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB, ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_m28C5FEE9DBE03CF72CF72C3E0CC494D3A9E9C233_inline (Span_1_t460BF9A574BE0955E6E375F5EDC0E0830FA47381* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t460BF9A574BE0955E6E375F5EDC0E0830FA47381*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A_m3D68438A3C5FAE6C4F026A5954BEBC6157069B6E (UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* ___0_destination, UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_m05FAEE8A43921FFBDAA0B10C45DF7B413F8B7795_inline (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357* __this, UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357*, UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD* Array_Empty_TisUnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A_m19F4090BD5440974029AFE51BC45A5C37D4D5C77_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_mB157614B5969EB80F641D18A4DB33C3D8FC885C1 (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357 ___0_left, ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357 ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357, ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_m9BA78DAEE8653BAD2B9ADFFE2B50A419DBA0E47E_inline (Span_1_t9DA7921D616AFD6EFF2CEF642A21C62ED20C6F05* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t9DA7921D616AFD6EFF2CEF642A21C62ED20C6F05*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73_mBDCCC7D03D4C397E8F32FB955EC547A2FDFA5543 (UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* ___0_destination, UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_m189B1065E7F68FCEFFD8B51369EE9310DF43AB4E_inline (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E* __this, UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E*, UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00* Array_Empty_TisUnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73_m38077BA7106C32737B0A147A292DAA166A65A743_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_m3EDB78E2FEE1B7D258823CFA9B42822972E7004D (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E ___0_left, ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E, ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_m45281C7FCFF81C6F91B1E8B0897FDFC91AB9AB2E_inline (Span_1_t83DEC692D54FF8BED9317442919944F109D8D9FB* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t83DEC692D54FF8BED9317442919944F109D8D9FB*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516_m996D3C06C347B6A640186D2FAC8C066B5DD1AAC2 (UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* ___0_destination, UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_mC5370B060FD7B513D4E024C074C86F97DBAFBB17_inline (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5* __this, UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5*, UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB* Array_Empty_TisUnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516_m2559F4EE41A1BC5F7F6D91695D46A1FFB8292C19_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_mD2406E85102C4510337D5938C7775580D1FD07B6 (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5 ___0_left, ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5 ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5, ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_mA59EA29AF3DD0FC655679A6085EE47B82CF64D41_inline (Span_1_t6BF1EBB3CB6E0BEE5E6E144F0324DFB047F18F32* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t6BF1EBB3CB6E0BEE5E6E144F0324DFB047F18F32*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB_m12DF3FA9D7727285D808AAECE8E2786E166C62EC (UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* ___0_destination, UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_m7E4F150F2960FADBE911D19F7D28C3988BA704BE_inline (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8* __this, UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8*, UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06* Array_Empty_TisUnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB_m198A5A706220D5563451F5718452BA9A56A72461_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_m9821AF644D61E565E36E9E2E52222A7DA94FA0B7 (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8 ___0_left, ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8 ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8, ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline int32_t Span_1_get_Length_m851E7466A7ADB4DA5BD951798802A989624EC76C_inline (Span_1_t399B9EFF21D03E62E3B6A8591A5B91D4B44A6649* __this, const RuntimeMethod* method)
{
	return ((  int32_t (*) (Span_1_t399B9EFF21D03E62E3B6A8591A5B91D4B44A6649*, const RuntimeMethod*))Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline)(__this, method);
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void Buffer_Memmove_TisUnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8_mB0F180342B1F4A1D35E400B23C6B7CAF85F63CD2 (UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* ___0_destination, UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* ___1_source, uint64_t ___2_elementCount, const RuntimeMethod* method) ;
inline void ReadOnlySpan_1__ctor_mC62CC2AF726A0EEE2B165E13BA155A4B09311BC8_inline (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8* __this, UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8*, UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8*, int32_t, const RuntimeMethod*))ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B* Array_Empty_TisUnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8_mBB7951BE7C90C20D302AF78E7CD56927C0AE123D_inline (const RuntimeMethod* method) ;
inline bool ReadOnlySpan_1_op_Equality_m4C28BFFAE59CC4D76A555A76D09850EE697F895B (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8 ___0_left, ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8 ___1_right, const RuntimeMethod* method)
{
	return ((  bool (*) (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8, ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8, const RuntimeMethod*))ReadOnlySpan_1_op_Equality_mCB01F92371372FA04CD22F603093A600A977916A_fshared)(___0_left, ___1_right, method);
}
inline void Span_1__ctor_m947BF95D54571BF3897F96822B7A8FDA5853497B_inline (Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305* __this, uint8_t* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method)
{
	((  void (*) (Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305*, uint8_t*, int32_t, const RuntimeMethod*))Span_1__ctor_mBA868F06359701D9950DEB1B10F52F848E9FF6DA_fshared_inline)(__this, ___0_ptr, ___1_length, method);
}
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_mA3718CBDAD334D0C3B3B3D9C2FBFFC64CB9C1280 (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B ReadOnlyCollection_1_get_Item_m8B59DAF06D65CB643DEBC41E31022C94ABFCF201 (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B L_2;
		L_2 = InterfaceFuncInvoker1< TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m226D99000078C09F61A5D23C9D572EEFD2C1F3AB (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_m0F0C917FD1406F4F32851B6001728D34FCF8F916 (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, TextureInfoU5BU5D_t0571178EAC2A0DE9A1F27F2C00A9301E04AAFB83* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		TextureInfoU5BU5D_t0571178EAC2A0DE9A1F27F2C00A9301E04AAFB83* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< TextureInfoU5BU5D_t0571178EAC2A0DE9A1F27F2C00A9301E04AAFB83*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_mE67F3699969AF5E867F200CCB537315190D8F228 (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m38FC28A8D172A809848EBBE17B7593C9A4AC5309 (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_m068D9D53938421BE65EC1E68460FE317576DE399 (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B L_2;
		L_2 = InterfaceFuncInvoker1< TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_m017BA78B6833B8E2C2CF7825DB54DAC7A82CF0AA (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	TextureInfoU5BU5D_t0571178EAC2A0DE9A1F27F2C00A9301E04AAFB83* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_mA3718CBDAD334D0C3B3B3D9C2FBFFC64CB9C1280(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((TextureInfoU5BU5D_t0571178EAC2A0DE9A1F27F2C00A9301E04AAFB83*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		TextureInfoU5BU5D_t0571178EAC2A0DE9A1F27F2C00A9301E04AAFB83* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		TextureInfoU5BU5D_t0571178EAC2A0DE9A1F27F2C00A9301E04AAFB83* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< TextureInfoU5BU5D_t0571178EAC2A0DE9A1F27F2C00A9301E04AAFB83*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B L_35;
			L_35 = InterfaceFuncInvoker1< TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_m42D884E04404CA71A624FD38BE1668900821FBBB (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B L_2;
		L_2 = InterfaceFuncInvoker1< TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mD22DEE1877768FD46CF1D7BE9E64A9BBF4762858 (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B));
		TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_m061D2F5226F935C163FEAC10BC96B6061FC7B3B4 (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mD22DEE1877768FD46CF1D7BE9E64A9BBF4762858(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_m226D99000078C09F61A5D23C9D572EEFD2C1F3AB(__this, ((*(TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_mE47DC91D620407A1DB7FB76011716B2E6E93D88B (ReadOnlyCollection_1_t82FFA6508CB53CD9CD9774F8D35B5FA03F04049E* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mD22DEE1877768FD46CF1D7BE9E64A9BBF4762858(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_m38FC28A8D172A809848EBBE17B7593C9A4AC5309(__this, ((*(TextureInfo_t581C305A0444F786E0E7405054714685BE3A5A5B*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m0AFB680989F7183252C477DD7EB9EF59D9C88ECC (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RaycastHitData_t5EAB266730389AB27715962670C2512800451841 ReadOnlyCollection_1_get_Item_m5884CA8614092EDE0411FE4E4BA9EE0533AD968C (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		RaycastHitData_t5EAB266730389AB27715962670C2512800451841 L_2;
		L_2 = InterfaceFuncInvoker1< RaycastHitData_t5EAB266730389AB27715962670C2512800451841, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m37A8647602E0715AC27FDFF43DABCCEF7701AEAB (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, RaycastHitData_t5EAB266730389AB27715962670C2512800451841 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		RaycastHitData_t5EAB266730389AB27715962670C2512800451841 L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, RaycastHitData_t5EAB266730389AB27715962670C2512800451841 >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_m5F082B47628439FCF310B67488B7BAC95F226B6F (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, RaycastHitDataU5BU5D_t98BBA3CE354036B88621172C27ED5C5DD7CB9279* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		RaycastHitDataU5BU5D_t98BBA3CE354036B88621172C27ED5C5DD7CB9279* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< RaycastHitDataU5BU5D_t98BBA3CE354036B88621172C27ED5C5DD7CB9279*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_m62AFB23540393AE6D40811F4B02DF2FB51F4BA4B (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mE1ABD3A991704C640186283F3DD505E3B9A77BB6 (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, RaycastHitData_t5EAB266730389AB27715962670C2512800451841 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		RaycastHitData_t5EAB266730389AB27715962670C2512800451841 L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, RaycastHitData_t5EAB266730389AB27715962670C2512800451841 >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RaycastHitData_t5EAB266730389AB27715962670C2512800451841 ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_m33916FAE71F1DA5215615B4EDDEC7EC00AB57E2B (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		RaycastHitData_t5EAB266730389AB27715962670C2512800451841 L_2;
		L_2 = InterfaceFuncInvoker1< RaycastHitData_t5EAB266730389AB27715962670C2512800451841, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_mAC87670FB05B0AAEDFA8540073A293C7B7692088 (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	RaycastHitDataU5BU5D_t98BBA3CE354036B88621172C27ED5C5DD7CB9279* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_m0AFB680989F7183252C477DD7EB9EF59D9C88ECC(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((RaycastHitDataU5BU5D_t98BBA3CE354036B88621172C27ED5C5DD7CB9279*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		RaycastHitDataU5BU5D_t98BBA3CE354036B88621172C27ED5C5DD7CB9279* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		RaycastHitDataU5BU5D_t98BBA3CE354036B88621172C27ED5C5DD7CB9279* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< RaycastHitDataU5BU5D_t98BBA3CE354036B88621172C27ED5C5DD7CB9279*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			RaycastHitData_t5EAB266730389AB27715962670C2512800451841 L_35;
			L_35 = InterfaceFuncInvoker1< RaycastHitData_t5EAB266730389AB27715962670C2512800451841, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			RaycastHitData_t5EAB266730389AB27715962670C2512800451841 L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_m330DB679D829648ECF5DEE0E33721487E7FF9595 (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		RaycastHitData_t5EAB266730389AB27715962670C2512800451841 L_2;
		L_2 = InterfaceFuncInvoker1< RaycastHitData_t5EAB266730389AB27715962670C2512800451841, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		RaycastHitData_t5EAB266730389AB27715962670C2512800451841 L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m052B85911C70FD4FE70D220FF791FAF6C6479F83 (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	RaycastHitData_t5EAB266730389AB27715962670C2512800451841 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(RaycastHitData_t5EAB266730389AB27715962670C2512800451841));
		RaycastHitData_t5EAB266730389AB27715962670C2512800451841 L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_mAD0F6827C00D83F54DE41A24AF223A40737989B5 (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m052B85911C70FD4FE70D220FF791FAF6C6479F83(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_m37A8647602E0715AC27FDFF43DABCCEF7701AEAB(__this, ((*(RaycastHitData_t5EAB266730389AB27715962670C2512800451841*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_m6DBCEC9DA9D6432848242D4594243B56DBD7A15A (ReadOnlyCollection_1_t73DCD6C4D5F3100950AD53A9D36C7DFD67E9D0A6* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m052B85911C70FD4FE70D220FF791FAF6C6479F83(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_mE1ABD3A991704C640186283F3DD505E3B9A77BB6(__this, ((*(RaycastHitData_t5EAB266730389AB27715962670C2512800451841*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m409F5776BEB430BE72273C433CC1850CD93700A7 (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 ReadOnlyCollection_1_get_Item_mC89B10C454A992A80E70F460707E3A96AE6AE1ED (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 L_2;
		L_2 = InterfaceFuncInvoker1< WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mDF174A6917D3D93C8D7910C91080D253891A1AC5 (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_m34129B777F4C0D729638A29403265448F67AAB7E (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, WorkRequestU5BU5D_t1B912B8BE58CF60CAF3A4FEC0A5C0F5BB6D99577* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		WorkRequestU5BU5D_t1B912B8BE58CF60CAF3A4FEC0A5C0F5BB6D99577* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< WorkRequestU5BU5D_t1B912B8BE58CF60CAF3A4FEC0A5C0F5BB6D99577*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_m3AE0234C0DA1C378A676F109CCB2CE268E405AB4 (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mC7204EA734A903659BFE12EFC2FD358391419441 (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_mB501D0309F1CC0BF9203CF948994D438621201BD (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 L_2;
		L_2 = InterfaceFuncInvoker1< WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_m44BBB5AB33E2C90225D466FD249C45ACCD42465C (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	WorkRequestU5BU5D_t1B912B8BE58CF60CAF3A4FEC0A5C0F5BB6D99577* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_m409F5776BEB430BE72273C433CC1850CD93700A7(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((WorkRequestU5BU5D_t1B912B8BE58CF60CAF3A4FEC0A5C0F5BB6D99577*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		WorkRequestU5BU5D_t1B912B8BE58CF60CAF3A4FEC0A5C0F5BB6D99577* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		WorkRequestU5BU5D_t1B912B8BE58CF60CAF3A4FEC0A5C0F5BB6D99577* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< WorkRequestU5BU5D_t1B912B8BE58CF60CAF3A4FEC0A5C0F5BB6D99577*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 L_35;
			L_35 = InterfaceFuncInvoker1< WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_m6177EFE8D98E3D7B7B5475B10665A5B4A0CED868 (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 L_2;
		L_2 = InterfaceFuncInvoker1< WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m297F49BCB3FD33C8DE274BA917FFF7B708758DB7 (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44));
		WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44 L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_m7BD692E11177D43D9730EE9D3CAE473ED0901007 (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m297F49BCB3FD33C8DE274BA917FFF7B708758DB7(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_mDF174A6917D3D93C8D7910C91080D253891A1AC5(__this, ((*(WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_mDC76BD09F10EE0179D32F61859653C019393CD2B (ReadOnlyCollection_1_tB59426B63A6357E19EEB6EAD530B26D450DAAD07* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m297F49BCB3FD33C8DE274BA917FFF7B708758DB7(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_mC7204EA734A903659BFE12EFC2FD358391419441(__this, ((*(WorkRequest_t8AF542F2E248D9234341817CDB5F76C27D348B44*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m31B5E7F8E3D51CB370BE05608F7B2C3C11EE0C55 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D ReadOnlyCollection_1_get_Item_m5AB43596F44CC288DA87BCA19EC8D9CF352BC830 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D L_2;
		L_2 = InterfaceFuncInvoker1< AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m6057F27D1ACAA9CBF4A9FFC87FDAA2ACC117A809 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_m3D5D6472653F81CBBF60F1A4F5FB285FE8FD81F4 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, AssetEntryU5BU5D_t83ECF66F13D78425A1AF86967D10F3FA0A0C123F* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		AssetEntryU5BU5D_t83ECF66F13D78425A1AF86967D10F3FA0A0C123F* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< AssetEntryU5BU5D_t83ECF66F13D78425A1AF86967D10F3FA0A0C123F*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_m73A5FD2B15474679BE446FD212642A0DFA1BDACC (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mD865206564138ED88C746288B0A9A6EB96555FC2 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_m5CAA0592F9EEFE14B9D85A067D8A48E463BD0255 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D L_2;
		L_2 = InterfaceFuncInvoker1< AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_mE829AA0EB6560D334DE747097153F5A357D552D3 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	AssetEntryU5BU5D_t83ECF66F13D78425A1AF86967D10F3FA0A0C123F* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_m31B5E7F8E3D51CB370BE05608F7B2C3C11EE0C55(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((AssetEntryU5BU5D_t83ECF66F13D78425A1AF86967D10F3FA0A0C123F*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		AssetEntryU5BU5D_t83ECF66F13D78425A1AF86967D10F3FA0A0C123F* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		AssetEntryU5BU5D_t83ECF66F13D78425A1AF86967D10F3FA0A0C123F* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< AssetEntryU5BU5D_t83ECF66F13D78425A1AF86967D10F3FA0A0C123F*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D L_35;
			L_35 = InterfaceFuncInvoker1< AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_mDA2999BA621C7C5B8E399FFFEBBFEC2075F03CFB (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D L_2;
		L_2 = InterfaceFuncInvoker1< AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m496DFF37E9CC6DE59F0E2B4E2A5DBEAA32DEAD94 (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D));
		AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_m01E51474F8560A28BE0B3BC89A91337DBA7CF7D3 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m496DFF37E9CC6DE59F0E2B4E2A5DBEAA32DEAD94(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_m6057F27D1ACAA9CBF4A9FFC87FDAA2ACC117A809(__this, ((*(AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_mF018250B690D9925EADF086DD08D674AFB5B8D59 (ReadOnlyCollection_1_t32D3583BA30824B44FED94CE41C1088BA7F66C69* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m496DFF37E9CC6DE59F0E2B4E2A5DBEAA32DEAD94(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_mD865206564138ED88C746288B0A9A6EB96555FC2(__this, ((*(AssetEntry_tEB6FC90E5BB63DCA4FF932F2D64595339A28806D*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m15D679310A0AC97586C8124180F5EB3E1D40A2BC (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 ReadOnlyCollection_1_get_Item_m6397C9E0F57C3E4112047E50BA57CF877EF7AA5E (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 L_2;
		L_2 = InterfaceFuncInvoker1< SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m9ADA09E692C504A400AF0D8E4BF59A7C3C2C8F93 (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_m9CEC885D66A757E55A1BCAAA81EE56C3331F7C80 (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, SlotDefinitionU5BU5D_t9003D04EBDD74C44DD8490A99624A727154E1299* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		SlotDefinitionU5BU5D_t9003D04EBDD74C44DD8490A99624A727154E1299* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< SlotDefinitionU5BU5D_t9003D04EBDD74C44DD8490A99624A727154E1299*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_m5281DA7E199DAF2110C2E3AC674BF46ED6E5A909 (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m942BE9C1C9D8A0392F495981442E058E887308CF (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_mADAE772B4BD15F8285463DB5CE3C374B3886B620 (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 L_2;
		L_2 = InterfaceFuncInvoker1< SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_mC35A16F6E2DB9422F719776935632AAC1B8CEF43 (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	SlotDefinitionU5BU5D_t9003D04EBDD74C44DD8490A99624A727154E1299* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_m15D679310A0AC97586C8124180F5EB3E1D40A2BC(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((SlotDefinitionU5BU5D_t9003D04EBDD74C44DD8490A99624A727154E1299*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		SlotDefinitionU5BU5D_t9003D04EBDD74C44DD8490A99624A727154E1299* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		SlotDefinitionU5BU5D_t9003D04EBDD74C44DD8490A99624A727154E1299* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< SlotDefinitionU5BU5D_t9003D04EBDD74C44DD8490A99624A727154E1299*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 L_35;
			L_35 = InterfaceFuncInvoker1< SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_m1FF003DF50C41FA0FE8F95E3E98170E1AC8394BB (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 L_2;
		L_2 = InterfaceFuncInvoker1< SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m948DB26D5A8A2DF64E9700A6DEB6F836B10749A3 (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8));
		SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8 L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_m4DABD32E7AACFC8A0443D40D2F09D045E7AE944B (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m948DB26D5A8A2DF64E9700A6DEB6F836B10749A3(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_m9ADA09E692C504A400AF0D8E4BF59A7C3C2C8F93(__this, ((*(SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_m85B208EB89FC3FC4D4874377BB2FABD4DDB604AB (ReadOnlyCollection_1_tF2ABA1656E36C231EEBB5C7CEED077E4AC8239B7* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m948DB26D5A8A2DF64E9700A6DEB6F836B10749A3(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_m942BE9C1C9D8A0392F495981442E058E887308CF(__this, ((*(SlotDefinition_t2E39E965BBE5A336DD1B93A115DD01044D1A66F8*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m299B4E260E97612F6BFD1965863F5EDB0D80889F (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 ReadOnlyCollection_1_get_Item_m60E6A62D890747F1AC1DC730E0D3FCE9D4E02F01 (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 L_2;
		L_2 = InterfaceFuncInvoker1< SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m705B2717517A6E1493976E0F972CEC791692FF97 (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_mC1257C5457DDC4F101CB1C6E13C3918EDA840EAA (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, SlotUsageEntryU5BU5D_t02CCAC4881F115443BE39FCBE8439A9DCFC1C67A* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		SlotUsageEntryU5BU5D_t02CCAC4881F115443BE39FCBE8439A9DCFC1C67A* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< SlotUsageEntryU5BU5D_t02CCAC4881F115443BE39FCBE8439A9DCFC1C67A*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_mE2C132C56C7624052D3E4DD98373FEC71D0C7CB4 (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mBE061D69DECDF68D566C15E465E25ECFCE11FCD3 (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_m10F1544185B2CAC61276C7FC78D4A1E5250030AE (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 L_2;
		L_2 = InterfaceFuncInvoker1< SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_m0AE5422374BE07A750F53B941582E1D7881D19C9 (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	SlotUsageEntryU5BU5D_t02CCAC4881F115443BE39FCBE8439A9DCFC1C67A* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_m299B4E260E97612F6BFD1965863F5EDB0D80889F(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((SlotUsageEntryU5BU5D_t02CCAC4881F115443BE39FCBE8439A9DCFC1C67A*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		SlotUsageEntryU5BU5D_t02CCAC4881F115443BE39FCBE8439A9DCFC1C67A* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		SlotUsageEntryU5BU5D_t02CCAC4881F115443BE39FCBE8439A9DCFC1C67A* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< SlotUsageEntryU5BU5D_t02CCAC4881F115443BE39FCBE8439A9DCFC1C67A*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 L_35;
			L_35 = InterfaceFuncInvoker1< SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_m2E8461F31879EC0FA0F5D99691AFAFB5A7346225 (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 L_2;
		L_2 = InterfaceFuncInvoker1< SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mBF48FC95A670E75A65647A9F7520AEB9AE4A0FE6 (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76));
		SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76 L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_m64537CE10B51851FBE9771726AFCC8AAF5CF02C8 (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mBF48FC95A670E75A65647A9F7520AEB9AE4A0FE6(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_m705B2717517A6E1493976E0F972CEC791692FF97(__this, ((*(SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_m199CADD8D916A7510EF043D4D33ADE50B0DFFD37 (ReadOnlyCollection_1_tB75E264D1AFFBCE0E99EF3B6508A1772E4F74135* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mBF48FC95A670E75A65647A9F7520AEB9AE4A0FE6(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_mBE061D69DECDF68D566C15E465E25ECFCE11FCD3(__this, ((*(SlotUsageEntry_t73A628038C799E4FD44436E093EC19D2B9EA1B76*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m05F05C64F32981A1BF2CEC3E7589604A188B612B (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 ReadOnlyCollection_1_get_Item_mF2270136C87C6CD47C4ED8B9CB895254931977C9 (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 L_2;
		L_2 = InterfaceFuncInvoker1< UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mD887308D8602D0A6C687F8B588F772CB0D0911A2 (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_mDA466383B01D8262103FE86D1BFABC09CADECA76 (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, UsingEntryU5BU5D_t3E321CB1464DE1D2F7FDE3790BD4AD8B72FBE811* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		UsingEntryU5BU5D_t3E321CB1464DE1D2F7FDE3790BD4AD8B72FBE811* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< UsingEntryU5BU5D_t3E321CB1464DE1D2F7FDE3790BD4AD8B72FBE811*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_m8F53882B80F14E008D7286F26BBF322554B99DBA (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mCC0B8F0541328E20D9E516ACE2AF53B44AA502ED (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_m4FF40A61AEA113EF82D13F16B3B2C6BF18B677E3 (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 L_2;
		L_2 = InterfaceFuncInvoker1< UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_m26C1285E73FDD195193E87CAE2B53B9D1237EB84 (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	UsingEntryU5BU5D_t3E321CB1464DE1D2F7FDE3790BD4AD8B72FBE811* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_m05F05C64F32981A1BF2CEC3E7589604A188B612B(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((UsingEntryU5BU5D_t3E321CB1464DE1D2F7FDE3790BD4AD8B72FBE811*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		UsingEntryU5BU5D_t3E321CB1464DE1D2F7FDE3790BD4AD8B72FBE811* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		UsingEntryU5BU5D_t3E321CB1464DE1D2F7FDE3790BD4AD8B72FBE811* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< UsingEntryU5BU5D_t3E321CB1464DE1D2F7FDE3790BD4AD8B72FBE811*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 L_35;
			L_35 = InterfaceFuncInvoker1< UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_mA86767BE1489730FEEF7C9B2F51CADDCB1AFE68A (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 L_2;
		L_2 = InterfaceFuncInvoker1< UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mBA2972FFD773AA00EC4BAD22D43C97C5FFFD31EA (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484));
		UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484 L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_mB58F33AA4E890E1EB6DC1BFAA71B1EAE2F5E5B48 (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mBA2972FFD773AA00EC4BAD22D43C97C5FFFD31EA(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_mD887308D8602D0A6C687F8B588F772CB0D0911A2(__this, ((*(UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_m45B400C577803964484B6C2318A986085887DF6E (ReadOnlyCollection_1_t03DF8DEE56271CB6F01A668065CE8A667D463CC4* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mBA2972FFD773AA00EC4BAD22D43C97C5FFFD31EA(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_mCC0B8F0541328E20D9E516ACE2AF53B44AA502ED(__this, ((*(UsingEntry_t0454AD34026FDFD1733CE07BD4AE807B0FBCE484*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_mCB408C9C0EF8BB4EAF3BD9D74210EA1BF645DF9F (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 ReadOnlyCollection_1_get_Item_mFD65FE8672CF437F4E56553136F3296603743E5B (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 L_2;
		L_2 = InterfaceFuncInvoker1< VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mA07C916646443F7E600B771BA5B6E3276CF6F38D (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_m373BF4F61459CBD0614937565D50D38211EC389D (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, VersionInfoU5BU5D_tA86713FC86D1EDA523BC741A17D81B20A869AE64* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		VersionInfoU5BU5D_tA86713FC86D1EDA523BC741A17D81B20A869AE64* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< VersionInfoU5BU5D_tA86713FC86D1EDA523BC741A17D81B20A869AE64*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_m627A159A926F95C24D2FC6C0A665BAE6B31C6210 (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m24635AF1EE0DBE26C00D1E919C331F3EC3514442 (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_mF2CBAC673542C78C4E66A0B63AB25F7E23E426F4 (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 L_2;
		L_2 = InterfaceFuncInvoker1< VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_mB9E303B104B18F639A07B580FCDCB916D8C5F43A (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	VersionInfoU5BU5D_tA86713FC86D1EDA523BC741A17D81B20A869AE64* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_mCB408C9C0EF8BB4EAF3BD9D74210EA1BF645DF9F(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((VersionInfoU5BU5D_tA86713FC86D1EDA523BC741A17D81B20A869AE64*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		VersionInfoU5BU5D_tA86713FC86D1EDA523BC741A17D81B20A869AE64* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		VersionInfoU5BU5D_tA86713FC86D1EDA523BC741A17D81B20A869AE64* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< VersionInfoU5BU5D_tA86713FC86D1EDA523BC741A17D81B20A869AE64*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 L_35;
			L_35 = InterfaceFuncInvoker1< VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_m7FF73F40502F4224B0A39DC1C6E21D7F62ED5320 (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 L_2;
		L_2 = InterfaceFuncInvoker1< VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mCB5B8ABED8FAA81E9313462E91E846577DBF79E7 (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8));
		VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8 L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_m21250661C6C1891AA59CA1F5DB154974346EB45E (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mCB5B8ABED8FAA81E9313462E91E846577DBF79E7(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_mA07C916646443F7E600B771BA5B6E3276CF6F38D(__this, ((*(VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_mBDF6671029CE751A5B90318650A9E1266C9FFBAC (ReadOnlyCollection_1_t8D2DFE1EAD5470CAE23C2E0016BE260592A57C65* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mCB5B8ABED8FAA81E9313462E91E846577DBF79E7(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_m24635AF1EE0DBE26C00D1E919C331F3EC3514442(__this, ((*(VersionInfo_tD8EF94E6EB7FCB9167CE193F9FFAAB6DE0518DE8*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_mCB4FF2AFAA94D01923F9242ACB66F817F7CF18C7 (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD ReadOnlyCollection_1_get_Item_m4534A86754FC3150BB56EE056CF44694CFD57C47 (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD L_2;
		L_2 = InterfaceFuncInvoker1< XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m116AE421F0EB30927F6725D62792FFA5A6065627 (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_m8AA5CBAE562679AFCE7394F17B403AAF1B7890E2 (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, XmlSchemaObjectEntryU5BU5D_tBCEE5881A0EF3ACBC998EFA679ACBF1ED8256E27* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		XmlSchemaObjectEntryU5BU5D_tBCEE5881A0EF3ACBC998EFA679ACBF1ED8256E27* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< XmlSchemaObjectEntryU5BU5D_tBCEE5881A0EF3ACBC998EFA679ACBF1ED8256E27*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_m183CC0AE8D94E74219F7F9C2466D2F7804BA497B (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mF523F5C22B1C3DFB9577177B1C50F9DC3B9704C2 (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_m00D2C57ECBF88B874CB68F5C81534469F56A4FEF (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD L_2;
		L_2 = InterfaceFuncInvoker1< XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_m4C097801325D2332FC1A226D23825CFF771B6ED6 (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	XmlSchemaObjectEntryU5BU5D_tBCEE5881A0EF3ACBC998EFA679ACBF1ED8256E27* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_mCB4FF2AFAA94D01923F9242ACB66F817F7CF18C7(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((XmlSchemaObjectEntryU5BU5D_tBCEE5881A0EF3ACBC998EFA679ACBF1ED8256E27*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		XmlSchemaObjectEntryU5BU5D_tBCEE5881A0EF3ACBC998EFA679ACBF1ED8256E27* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		XmlSchemaObjectEntryU5BU5D_tBCEE5881A0EF3ACBC998EFA679ACBF1ED8256E27* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< XmlSchemaObjectEntryU5BU5D_tBCEE5881A0EF3ACBC998EFA679ACBF1ED8256E27*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD L_35;
			L_35 = InterfaceFuncInvoker1< XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_mEA0B17247D97DD5D3CB64691624A04D50BCA99A1 (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD L_2;
		L_2 = InterfaceFuncInvoker1< XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mC5B4A17FCA21C2DF1F66767E828535AD34B90513 (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD));
		XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_mBD795131F32122B764751DC7B95C0ED36D0371AA (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mC5B4A17FCA21C2DF1F66767E828535AD34B90513(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_m116AE421F0EB30927F6725D62792FFA5A6065627(__this, ((*(XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_mCCDA3835E895D0768BB7B32D130DDF9C4FD557C8 (ReadOnlyCollection_1_t9309D20294B0D49BDEA1E5D7CF07BB04A6F32568* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mC5B4A17FCA21C2DF1F66767E828535AD34B90513(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_mF523F5C22B1C3DFB9577177B1C50F9DC3B9704C2(__this, ((*(XmlSchemaObjectEntry_t79D1310E1F5CA860FAD243853E59A3C2ACDB83CD*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m8458978F11950358DAF515D9793F94E96E164867 (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E ReadOnlyCollection_1_get_Item_m27C60ADC9D3F27B6DE1E527CB213B2F315F09971 (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E L_2;
		L_2 = InterfaceFuncInvoker1< VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mE296E176CF781CFBEDEA890CD7B7438707C5CBC2 (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_m242D80A80BCA864DE06422CE7A0AD846E91870C3 (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, VolumeParameterChainU5BU5D_t0474622D9FD8B1CC198D56824468949D1E1C680F* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		VolumeParameterChainU5BU5D_t0474622D9FD8B1CC198D56824468949D1E1C680F* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< VolumeParameterChainU5BU5D_t0474622D9FD8B1CC198D56824468949D1E1C680F*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_mBCFE48F26F4626AE0ECC7E048A8CE902E619C243 (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m25AC6AFADC9DA3C7616FB3DF2538489069FE82FF (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_m79AFAF6B4C025D04CED3F7A6CEEE4C0AEDF09FC0 (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E L_2;
		L_2 = InterfaceFuncInvoker1< VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_mC52C7CC07686EB43525D65DC943ACD1CF6E38106 (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	VolumeParameterChainU5BU5D_t0474622D9FD8B1CC198D56824468949D1E1C680F* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_m8458978F11950358DAF515D9793F94E96E164867(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((VolumeParameterChainU5BU5D_t0474622D9FD8B1CC198D56824468949D1E1C680F*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		VolumeParameterChainU5BU5D_t0474622D9FD8B1CC198D56824468949D1E1C680F* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		VolumeParameterChainU5BU5D_t0474622D9FD8B1CC198D56824468949D1E1C680F* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< VolumeParameterChainU5BU5D_t0474622D9FD8B1CC198D56824468949D1E1C680F*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E L_35;
			L_35 = InterfaceFuncInvoker1< VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_m1B4F3750ED4A1C2557520A532E4AE71F1F78870E (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E L_2;
		L_2 = InterfaceFuncInvoker1< VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m0F15E0EC055DA3F521E73184206A61A28D6E1C0F (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E));
		VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_m30D3408DB81CC07D32C804A176F112FD8627B192 (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m0F15E0EC055DA3F521E73184206A61A28D6E1C0F(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_mE296E176CF781CFBEDEA890CD7B7438707C5CBC2(__this, ((*(VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_m70B38A80F2FAF67F7336339F89B2A3851478DA77 (ReadOnlyCollection_1_t94E1EAD664D431DAF5233CA9EF20FF855C992227* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m0F15E0EC055DA3F521E73184206A61A28D6E1C0F(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_m25AC6AFADC9DA3C7616FB3DF2538489069FE82FF(__this, ((*(VolumeParameterChain_tF0AF946FA26C5D61B2713BA220DD70D041EAA35E*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_mCFEB25EF1344B976A050CB6937362A3F5DF0199A (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 ReadOnlyCollection_1_get_Item_mB4FBA6653B45B885F77168D2A31246E86A61239C (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 L_2;
		L_2 = InterfaceFuncInvoker1< ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m3CAC4C8BA133B39A5BA9FA0A1E0E711E09BD7694 (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_m98B2AA9918F58E13BC7615C283CD2A2B5AC5BA2F (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, ContextMenuItemU5BU5D_tFD4FC81929646BCD206377E2AC8E290E93FEE279* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		ContextMenuItemU5BU5D_tFD4FC81929646BCD206377E2AC8E290E93FEE279* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< ContextMenuItemU5BU5D_tFD4FC81929646BCD206377E2AC8E290E93FEE279*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_mAA1BF20823EFD08F455F9177A2BADBCF07470285 (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mE8080B23EA1AD670E7D7D77D172A6973A222ED2C (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_mD2A608FF40630292908E8D69A6102C27001FC717 (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 L_2;
		L_2 = InterfaceFuncInvoker1< ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_mCF1AC1CDAFDA110866DACF9EE9A70AEC9AA0BE4D (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	ContextMenuItemU5BU5D_tFD4FC81929646BCD206377E2AC8E290E93FEE279* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_mCFEB25EF1344B976A050CB6937362A3F5DF0199A(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((ContextMenuItemU5BU5D_tFD4FC81929646BCD206377E2AC8E290E93FEE279*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		ContextMenuItemU5BU5D_tFD4FC81929646BCD206377E2AC8E290E93FEE279* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		ContextMenuItemU5BU5D_tFD4FC81929646BCD206377E2AC8E290E93FEE279* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< ContextMenuItemU5BU5D_tFD4FC81929646BCD206377E2AC8E290E93FEE279*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 L_35;
			L_35 = InterfaceFuncInvoker1< ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_m8EAA569D28A7BEE2BF68701BDCE7E3F7230F0A39 (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 L_2;
		L_2 = InterfaceFuncInvoker1< ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m3A0010FDAC2908AF80DDEB4BA4458869F0FE9F8F (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9));
		ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9 L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_m67E991E768D997905AAE39961F6EE846E0859535 (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m3A0010FDAC2908AF80DDEB4BA4458869F0FE9F8F(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_m3CAC4C8BA133B39A5BA9FA0A1E0E711E09BD7694(__this, ((*(ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_mDE2CF32E3C5F436DD6FA819744A0876F36859728 (ReadOnlyCollection_1_t4E57872B64C17ACE2E87B5BBEEB28AB5B627DDBC* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m3A0010FDAC2908AF80DDEB4BA4458869F0FE9F8F(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_mE8080B23EA1AD670E7D7D77D172A6973A222ED2C(__this, ((*(ContextMenuItem_t0D29D1ECB0C1F769EFC9ACA2D0AE6B1A8A4736A9*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m88DC99D667337D16893CDF63694D22FEAF331E05 (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 ReadOnlyCollection_1_get_Item_m0A91A846BBC91E711D2FD276F926C8622F725207 (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 L_2;
		L_2 = InterfaceFuncInvoker1< LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m9FE5CCC2B059229D4C97248D4F5E82C20ECB5FBE (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_m2E2F7FE9FE98257542D040CCB5A505040BB765DD (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, LayoutMatcherU5BU5D_t790C71C3787F12C3EE9F7ABDC24DFCEB5281F90E* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		LayoutMatcherU5BU5D_t790C71C3787F12C3EE9F7ABDC24DFCEB5281F90E* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< LayoutMatcherU5BU5D_t790C71C3787F12C3EE9F7ABDC24DFCEB5281F90E*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_m77826D7B702325BB85B22D685A41A3BDBF2E6DFE (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m093DAAF13F65B6DE09B24D00F36FCC13F61E6E15 (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_m00749260A028B5DAE550D78E7C08AA80CB178383 (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 L_2;
		L_2 = InterfaceFuncInvoker1< LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_m97E025565D89BA957D0D7595F9930CB1EBA802FD (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	LayoutMatcherU5BU5D_t790C71C3787F12C3EE9F7ABDC24DFCEB5281F90E* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_m88DC99D667337D16893CDF63694D22FEAF331E05(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((LayoutMatcherU5BU5D_t790C71C3787F12C3EE9F7ABDC24DFCEB5281F90E*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		LayoutMatcherU5BU5D_t790C71C3787F12C3EE9F7ABDC24DFCEB5281F90E* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		LayoutMatcherU5BU5D_t790C71C3787F12C3EE9F7ABDC24DFCEB5281F90E* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< LayoutMatcherU5BU5D_t790C71C3787F12C3EE9F7ABDC24DFCEB5281F90E*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 L_35;
			L_35 = InterfaceFuncInvoker1< LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_m91FB5557DA051340EECCD4F9A13275A509B5379B (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 L_2;
		L_2 = InterfaceFuncInvoker1< LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m9E692C71C0193F22ACD65EEFBA4ECA75E5C53AAD (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6));
		LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6 L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_m07AAC581ACA363E09C760153D0F5634069AAEF43 (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m9E692C71C0193F22ACD65EEFBA4ECA75E5C53AAD(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_m9FE5CCC2B059229D4C97248D4F5E82C20ECB5FBE(__this, ((*(LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_m28EE46B044CC3F881E8EEF91F1FB3C37C601376C (ReadOnlyCollection_1_t219F9DE246A267F098345182628B7967858ED247* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m9E692C71C0193F22ACD65EEFBA4ECA75E5C53AAD(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_m093DAAF13F65B6DE09B24D00F36FCC13F61E6E15(__this, ((*(LayoutMatcher_t0D8F5E32A7C82BC292EBA0FAA3EB2D9F1F72A0A6*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m283266AC4D77DC2424BDBD9CB125A1A61AB55E1C (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D ReadOnlyCollection_1_get_Item_m7AC6E00BD2F6EA75A1E1B09ED4B82A4098110EF3 (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D L_2;
		L_2 = InterfaceFuncInvoker1< InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m7535255C244884FCE69E71A597A10D82C38A21AB (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_mA1B55098F63BA27BE711D1D31130C38B32CB2736 (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, InstructionViewU5BU5D_t2A200DCB627CD67C1DDBD22595A355894F2646A3* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		InstructionViewU5BU5D_t2A200DCB627CD67C1DDBD22595A355894F2646A3* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< InstructionViewU5BU5D_t2A200DCB627CD67C1DDBD22595A355894F2646A3*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_mDAEDE4966E056491EDD88CFC26EDCADE3C46EA26 (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m07CEF5EB192EFDA22EC079165EEE0F82A03E5FD7 (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_m1B2ADAE698787A805757D5552B8621296703F2E9 (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D L_2;
		L_2 = InterfaceFuncInvoker1< InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_m9742AA735CF66DE2EBB0A96F4D32E09171B49041 (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	InstructionViewU5BU5D_t2A200DCB627CD67C1DDBD22595A355894F2646A3* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_m283266AC4D77DC2424BDBD9CB125A1A61AB55E1C(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((InstructionViewU5BU5D_t2A200DCB627CD67C1DDBD22595A355894F2646A3*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		InstructionViewU5BU5D_t2A200DCB627CD67C1DDBD22595A355894F2646A3* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		InstructionViewU5BU5D_t2A200DCB627CD67C1DDBD22595A355894F2646A3* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< InstructionViewU5BU5D_t2A200DCB627CD67C1DDBD22595A355894F2646A3*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D L_35;
			L_35 = InterfaceFuncInvoker1< InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_m24710EB1D21C4B8F4BB3D9D2056EFCB3DE939181 (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D L_2;
		L_2 = InterfaceFuncInvoker1< InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mD7979063F69DBCBBA075F88868B40DE92ED347FC (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D));
		InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_mC2D64D9B1CEC419CEF540449FBC051217E2AA963 (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mD7979063F69DBCBBA075F88868B40DE92ED347FC(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_m7535255C244884FCE69E71A597A10D82C38A21AB(__this, ((*(InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_mF41F8CBA905BB1AB7C399429BF5691110460D2BB (ReadOnlyCollection_1_tB919AFBB5D00764975FBCFA46BD779234DFFA466* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mD7979063F69DBCBBA075F88868B40DE92ED347FC(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_m07CEF5EB192EFDA22EC079165EEE0F82A03E5FD7(__this, ((*(InstructionView_tA381D8A27DEDDEE43C71B3BB3A2FADC0CD059A3D*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m818A3E47FE33091DD1275D2DFDF70695E715E185 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F ReadOnlyCollection_1_get_Item_m6EB60D34CA0BE21AE6C2908D8CE1058DEFEC7ACC (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F L_2;
		L_2 = InterfaceFuncInvoker1< PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_m3006B42AEF364FAED734490926CA034ED5348569 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_m2D5B34537E9E88D61CE6DE65DA8E4ED641EB3412 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, PassDataU5BU5D_tF21A03049926F4AE1289DBF568C76ED64042A9FC* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		PassDataU5BU5D_tF21A03049926F4AE1289DBF568C76ED64042A9FC* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< PassDataU5BU5D_tF21A03049926F4AE1289DBF568C76ED64042A9FC*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_m21221C7CFD70D8A1E5963C9CDB0967B1361B8862 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m4D42E127F9A2F6A6D223785F8CA656A4930B87C2 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_mF564FD5A7A7060A271DCFBBC8A415AB7A76F20C1 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F L_2;
		L_2 = InterfaceFuncInvoker1< PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_mF9EA85ACDC0EF457938D363BAFC351F38291161D (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	PassDataU5BU5D_tF21A03049926F4AE1289DBF568C76ED64042A9FC* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_m818A3E47FE33091DD1275D2DFDF70695E715E185(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((PassDataU5BU5D_tF21A03049926F4AE1289DBF568C76ED64042A9FC*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		PassDataU5BU5D_tF21A03049926F4AE1289DBF568C76ED64042A9FC* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		PassDataU5BU5D_tF21A03049926F4AE1289DBF568C76ED64042A9FC* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< PassDataU5BU5D_tF21A03049926F4AE1289DBF568C76ED64042A9FC*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F L_35;
			L_35 = InterfaceFuncInvoker1< PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_mB766727BF7DB38B182F8140AA0BFF30A2876EE26 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F L_2;
		L_2 = InterfaceFuncInvoker1< PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m9E090EF8DAC5EB1362F55C11AC2FD29FE307A954 (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F));
		PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_mBB60F8752EE0A063BE174C1034872A826F05E331 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m9E090EF8DAC5EB1362F55C11AC2FD29FE307A954(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_m3006B42AEF364FAED734490926CA034ED5348569(__this, ((*(PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_mEAFE167288B6716BC550C1AEDEC66E25A61C8E18 (ReadOnlyCollection_1_t5B9BEDC95C484389997D167F070E30505719DE4D* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m9E090EF8DAC5EB1362F55C11AC2FD29FE307A954(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_m4D42E127F9A2F6A6D223785F8CA656A4930B87C2(__this, ((*(PassData_t70EFDE0ED44B50E9E144E803C17DE2373723887F*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m0730B9BAC8092A41B1C48042F79C306FD18E553F (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 ReadOnlyCollection_1_get_Item_mF9FA72847D5DA338D66D016E4FB297385FB9A42E (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 L_2;
		L_2 = InterfaceFuncInvoker1< ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mD6916963F70388076B4D8A005C8C1AC7DB630642 (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_mA42C7EDA1BAF578D320D80F48E0647C110ADD681 (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, ResourceDataU5BU5D_t7EB547044DA870E25BACFEDEFCCD7821FE72022B* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		ResourceDataU5BU5D_t7EB547044DA870E25BACFEDEFCCD7821FE72022B* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< ResourceDataU5BU5D_t7EB547044DA870E25BACFEDEFCCD7821FE72022B*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_mB84E20F8BA5119B21FD4984601C9A70C64C57C52 (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mEAC3EE66A5CB94BE471210EA64A682C55D8463D0 (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_mA1A935A7DA00C54303DF2E52B8AFCFC4BA64E51A (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 L_2;
		L_2 = InterfaceFuncInvoker1< ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_m3CC70612B859C690D9C3531703CE753DF1B647EC (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	ResourceDataU5BU5D_t7EB547044DA870E25BACFEDEFCCD7821FE72022B* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_m0730B9BAC8092A41B1C48042F79C306FD18E553F(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((ResourceDataU5BU5D_t7EB547044DA870E25BACFEDEFCCD7821FE72022B*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		ResourceDataU5BU5D_t7EB547044DA870E25BACFEDEFCCD7821FE72022B* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		ResourceDataU5BU5D_t7EB547044DA870E25BACFEDEFCCD7821FE72022B* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< ResourceDataU5BU5D_t7EB547044DA870E25BACFEDEFCCD7821FE72022B*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 L_35;
			L_35 = InterfaceFuncInvoker1< ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_mB71CAA326A4ACDF03E75906564872A478196DBF9 (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 L_2;
		L_2 = InterfaceFuncInvoker1< ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_m718A868545EA0ABD0015911A27C3815E8A95752D (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3));
		ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3 L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_mCE36C4978C8E258E0C77969A66E4C55E374D1CB8 (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m718A868545EA0ABD0015911A27C3815E8A95752D(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_mD6916963F70388076B4D8A005C8C1AC7DB630642(__this, ((*(ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_m5DADB45967A9C3E8795B4E777233868592A3956E (ReadOnlyCollection_1_t6354AFE67B5ECFE646A867BDA68157E8795ED5B4* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_m718A868545EA0ABD0015911A27C3815E8A95752D(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_mEAC3EE66A5CB94BE471210EA64A682C55D8463D0(__this, ((*(ResourceData_t78BFD0FF4432C51882F5558EEDF6A8925F4F28B3*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m8B2AEA509E07E389B797D3576C0DDF9A5551E3A4 (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 ReadOnlyCollection_1_get_Item_m586F777658B145682E70A3FCE202B5FEE78F8F18 (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 L_2;
		L_2 = InterfaceFuncInvoker1< EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mD750C5DD43B49E3369FF1CC3778B43D83F58636E (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_mF318B9F02EA7AE7C2734AC064B64ED94C16F8798 (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, EntryProcessingInfoU5BU5D_tAB0CBF4A4379F39BA667FBBFCB22E4174C4D319B* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		EntryProcessingInfoU5BU5D_tAB0CBF4A4379F39BA667FBBFCB22E4174C4D319B* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< EntryProcessingInfoU5BU5D_tAB0CBF4A4379F39BA667FBBFCB22E4174C4D319B*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_m7C08CE459BEEDC1DF2952F054F69A3482C2433F6 (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_mDA0A610D1FE508DC17DABD5A4D5D861295857416 (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_m5D48D4159D5115984C187FE5B07D9140556FDA49 (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 L_2;
		L_2 = InterfaceFuncInvoker1< EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_m8958097E6E660BACA1709F0424DE966BF89439FD (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	EntryProcessingInfoU5BU5D_tAB0CBF4A4379F39BA667FBBFCB22E4174C4D319B* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_m8B2AEA509E07E389B797D3576C0DDF9A5551E3A4(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((EntryProcessingInfoU5BU5D_tAB0CBF4A4379F39BA667FBBFCB22E4174C4D319B*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		EntryProcessingInfoU5BU5D_tAB0CBF4A4379F39BA667FBBFCB22E4174C4D319B* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		EntryProcessingInfoU5BU5D_tAB0CBF4A4379F39BA667FBBFCB22E4174C4D319B* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< EntryProcessingInfoU5BU5D_tAB0CBF4A4379F39BA667FBBFCB22E4174C4D319B*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 L_35;
			L_35 = InterfaceFuncInvoker1< EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_mAC7741CB7BECB294DA1E38E3745C58853F0A197A (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 L_2;
		L_2 = InterfaceFuncInvoker1< EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mC9A90AF46B6E7EC8BC710283B87EB110801FAB1B (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289));
		EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289 L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_mC6029EF4ADA5CF37C75A5D189C30F6EEF696996C (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mC9A90AF46B6E7EC8BC710283B87EB110801FAB1B(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_mD750C5DD43B49E3369FF1CC3778B43D83F58636E(__this, ((*(EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_mF634A5AA11D90AB73EE09FC2DA892D8C98BD76E1 (ReadOnlyCollection_1_t537840A047E12157FC8F008F8986460D6E1ED235* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mC9A90AF46B6E7EC8BC710283B87EB110801FAB1B(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_mDA0A610D1FE508DC17DABD5A4D5D861295857416(__this, ((*(EntryProcessingInfo_tE4803801829E2739380552B9DE313B056A9C9289*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_get_Count_m5BD62585103C935CC4B20021B610D1D480BE6F19 (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 ReadOnlyCollection_1_get_Item_mDB5391F21C03A541CD55AAEEDE20775B401A9B0F (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 L_2;
		L_2 = InterfaceFuncInvoker1< PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_Contains_mC061A8BAB0855DF9F3365468CFE7C6897B27DB66 (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 L_1 = ___0_value;
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1< bool, PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_CopyTo_mDCD28C7482420D9DBA17845A440A0928A68429FA (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, PassCompatibilityInfoU5BU5D_t7B46D72837B465DBE4D623FD609B34DE43FE3317* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		PassCompatibilityInfoU5BU5D_t7B46D72837B465DBE4D623FD609B34DE43FE3317* L_1 = ___0_array;
		int32_t L_2 = ___1_index;
		NullCheck(L_0);
		InterfaceActionInvoker2< PassCompatibilityInfoU5BU5D_t7B46D72837B465DBE4D623FD609B34DE43FE3317*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_GetEnumerator_mD96010D6ACA8DBED4391371570F48D8592665CE9 (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		NullCheck(L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 7), L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_IndexOf_m91DD8D51560F4B4A6690B2B4DCF114816973A693 (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 L_1 = ___0_value;
		NullCheck(L_0);
		int32_t L_2;
		L_2 = InterfaceFuncInvoker1< int32_t, PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 ReadOnlyCollection_1_System_Collections_Generic_IListU3CTU3E_get_Item_mFDAFCF3888D2F84E5825B20EB17C904A41553B12 (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 L_2;
		L_2 = InterfaceFuncInvoker1< PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyCollection_1_System_Collections_ICollection_CopyTo_m47B9326BE9528881CB7336D37DFE3226E23E55FE (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(Type_t_StaticInit);
	PassCompatibilityInfoU5BU5D_t7B46D72837B465DBE4D623FD609B34DE43FE3317* V_0 = NULL;
	Type_t* V_1 = NULL;
	Type_t* V_2 = NULL;
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_3 = NULL;
	int32_t V_4 = 0;
	int32_t V_5 = 0;
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0009;
		}
	}
	{
		ThrowHelper_ThrowArgumentNullException_m05B7DB75576C421D7CA84FA73F84D7E114974CEC(3, NULL);
	}

IL_0009:
	{
		RuntimeArray* L_1 = ___0_array;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = il2cpp_codegen_array_get_rank(L_1);
		if ((((int32_t)L_2) == ((int32_t)1)))
		{
			goto IL_0018;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(7, NULL);
	}

IL_0018:
	{
		RuntimeArray* L_3 = ___0_array;
		NullCheck(L_3);
		int32_t L_4;
		L_4 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_3, 0, NULL);
		if (!L_4)
		{
			goto IL_0027;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(6, NULL);
	}

IL_0027:
	{
		int32_t L_5 = ___1_index;
		if ((((int32_t)L_5) >= ((int32_t)0)))
		{
			goto IL_0030;
		}
	}
	{
		ThrowHelper_ThrowIndexArgumentOutOfRange_NeedNonNegNumException_m57AAB1E093F20BFC64BDDBD90FB5B592F582B82F(NULL);
	}

IL_0030:
	{
		RuntimeArray* L_6 = ___0_array;
		NullCheck(L_6);
		int32_t L_7;
		L_7 = il2cpp_codegen_array_get_length(L_6);
		int32_t L_8 = ___1_index;
		int32_t L_9;
		L_9 = ReadOnlyCollection_1_get_Count_m5BD62585103C935CC4B20021B610D1D480BE6F19(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 10));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_7, L_8))) >= ((int32_t)L_9)))
		{
			goto IL_0046;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_m698044D4F664D7D0DDB88124EEEE2D052AF628BA(5, NULL);
	}

IL_0046:
	{
		RuntimeArray* L_10 = ___0_array;
		V_0 = ((PassCompatibilityInfoU5BU5D_t7B46D72837B465DBE4D623FD609B34DE43FE3317*)IsInstSealed((RuntimeObject*)L_10, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 11)));
		PassCompatibilityInfoU5BU5D_t7B46D72837B465DBE4D623FD609B34DE43FE3317* L_11 = V_0;
		if (!L_11)
		{
			goto IL_005e;
		}
	}
	{
		RuntimeObject* L_12 = __this->___list;
		PassCompatibilityInfoU5BU5D_t7B46D72837B465DBE4D623FD609B34DE43FE3317* L_13 = V_0;
		int32_t L_14 = ___1_index;
		NullCheck(L_12);
		InterfaceActionInvoker2< PassCompatibilityInfoU5BU5D_t7B46D72837B465DBE4D623FD609B34DE43FE3317*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_12, L_13, L_14);
		return;
	}

IL_005e:
	{
		RuntimeArray* L_15 = ___0_array;
		NullCheck(L_15);
		Type_t* L_16;
		L_16 = il2cpp_codegen_object_get_type(L_15);
		NullCheck(L_16);
		Type_t* L_17;
		L_17 = VirtualFuncInvoker0< Type_t* >::Invoke(47, L_16);
		V_1 = L_17;
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_18 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(il2cpp_codegen_method_rgctx(method), 12)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_19;
		L_19 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_18, NULL);
		V_2 = L_19;
		Type_t* L_20 = V_1;
		Type_t* L_21 = V_2;
		NullCheck(L_20);
		bool L_22;
		L_22 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_20, L_21);
		if (L_22)
		{
			goto IL_008c;
		}
	}
	{
		Type_t* L_23 = V_2;
		Type_t* L_24 = V_1;
		NullCheck(L_23);
		bool L_25;
		L_25 = VirtualFuncInvoker1< bool, Type_t* >::Invoke(23, L_23, L_24);
		if (L_25)
		{
			goto IL_008c;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_008c:
	{
		RuntimeArray* L_26 = ___0_array;
		V_3 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_26, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_27 = V_3;
		if (L_27)
		{
			goto IL_009b;
		}
	}
	{
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
	}

IL_009b:
	{
		RuntimeObject* L_28 = __this->___list;
		NullCheck(L_28);
		int32_t L_29;
		L_29 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_28);
		V_4 = L_29;
	}
	try
	{
		{
			V_5 = 0;
			goto IL_00cd_1;
		}

IL_00ad_1:
		{
			ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_30 = V_3;
			int32_t L_31 = ___1_index;
			int32_t L_32 = L_31;
			___1_index = ((int32_t)il2cpp_codegen_add(L_32, 1));
			RuntimeObject* L_33 = __this->___list;
			int32_t L_34 = V_5;
			NullCheck(L_33);
			PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 L_35;
			L_35 = InterfaceFuncInvoker1< PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_33, L_34);
			PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 L_36 = L_35;
			RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_36);
			NullCheck(L_30);
			ArrayElementTypeCheck (L_30, L_37);
			(L_30)->SetAt(static_cast<il2cpp_array_size_t>(L_32), (RuntimeObject*)L_37);
			int32_t L_38 = V_5;
			V_5 = ((int32_t)il2cpp_codegen_add(L_38, 1));
		}

IL_00cd_1:
		{
			int32_t L_39 = V_5;
			int32_t L_40 = V_4;
			if ((((int32_t)L_39) < ((int32_t)L_40)))
			{
				goto IL_00ad_1;
			}
		}
		{
			goto IL_00dd;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_00d5;
		}
		throw e;
	}

CATCH_00d5:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_41 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ThrowHelper_ThrowArgumentException_Argument_InvalidArrayType_m469A6A5731A0F1E94D8B609ED9D001C3A1652A58(NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		goto IL_00dd;
	}

IL_00dd:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyCollection_1_System_Collections_IList_get_Item_mFB260CCC81131D42BBC60B530874B1242ACE93FB (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___list;
		int32_t L_1 = ___0_index;
		NullCheck(L_0);
		PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 L_2;
		L_2 = InterfaceFuncInvoker1< PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3, int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 2), L_0, L_1);
		PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 L_3 = L_2;
		RuntimeObject* L_4 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4), &L_3);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_IsCompatibleObject_mC38E543F0BA4C1931B8FDCDA225802CE37FBD971 (RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		RuntimeObject* L_0 = ___0_value;
		if (((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))))
		{
			goto IL_001f;
		}
	}
	{
		RuntimeObject* L_1 = ___0_value;
		if (L_1)
		{
			goto IL_001d;
		}
	}
	{
		il2cpp_codegen_initobj((&V_0), sizeof(PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3));
		PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3 L_2 = V_0;
		return false;
	}

IL_001d:
	{
		return (bool)0;
	}

IL_001f:
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyCollection_1_System_Collections_IList_Contains_m8711E20808D5FAEED1F14B95371E43C309AD8B31 (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mC38E543F0BA4C1931B8FDCDA225802CE37FBD971(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		bool L_3;
		L_3 = ReadOnlyCollection_1_Contains_mC061A8BAB0855DF9F3365468CFE7C6897B27DB66(__this, ((*(PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 14));
		return L_3;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyCollection_1_System_Collections_IList_IndexOf_m3A46C0E6A81DD7844E346E5E9A60C5AB27538505 (ReadOnlyCollection_1_tC4D78C5AC16950429CBABEB2E20BE027AD31F434* __this, RuntimeObject* ___0_value, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = ___0_value;
		bool L_1;
		L_1 = ReadOnlyCollection_1_IsCompatibleObject_mC38E543F0BA4C1931B8FDCDA225802CE37FBD971(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 13));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_value;
		int32_t L_3;
		L_3 = ReadOnlyCollection_1_IndexOf_m91DD8D51560F4B4A6690B2B4DCF114816973A693(__this, ((*(PassCompatibilityInfo_tD79DCD78EC09F9D22A9E203048C684EEC9C237F3*)UnBox(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 4)))), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 15));
		return L_3;
	}

IL_0015:
	{
		return (-1);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221* ReadOnlyDictionary_2_get_Keys_m3D38C4849A0CBA72A3BEC65E1F8DBBEA252E34F0_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221* L_0 = __this->____keys;
		if (L_0)
		{
			goto IL_001e;
		}
	}
	{
		RuntimeObject* L_1 = __this->___m_dictionary;
		NullCheck(L_1);
		RuntimeObject* L_2;
		L_2 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(2, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_1);
		KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221* L_3 = (KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221*)il2cpp_codegen_object_new(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 2));
		((  void (*) (KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221*, RuntimeObject*, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 3)))(L_3, L_2, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 3));
		__this->____keys = L_3;
		Il2CppCodeGenWriteBarrier((void**)(&__this->____keys), (void*)L_3);
	}

IL_001e:
	{
		KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221* L_4 = __this->____keys;
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849* ReadOnlyDictionary_2_get_Values_m8896F49C0945D79E3B09562D2CDC7582F2FD7328_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849* L_0 = __this->____values;
		if (L_0)
		{
			goto IL_001e;
		}
	}
	{
		RuntimeObject* L_1 = __this->___m_dictionary;
		NullCheck(L_1);
		RuntimeObject* L_2;
		L_2 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(3, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_1);
		ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849* L_3 = (ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849*)il2cpp_codegen_object_new(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 5));
		((  void (*) (ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849*, RuntimeObject*, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 6)))(L_3, L_2, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 6));
		__this->____values = L_3;
		Il2CppCodeGenWriteBarrier((void**)(&__this->____values), (void*)L_3);
	}

IL_001e:
	{
		ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849* L_4 = __this->____values;
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyDictionary_2_ContainsKey_mE23701A23F87A60B1BCF98D9292D94BB14ADE64C_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, Il2CppFullySharedGenericAny ___0_key, const RuntimeMethod* method) 
{
	const uint32_t SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3 = il2cpp_codegen_sizeof(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7));
	const Il2CppFullySharedGenericAny L_1 = alloca(SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3);
	{
		RuntimeObject* L_0 = __this->___m_dictionary;
		il2cpp_codegen_memcpy(L_1, (il2cpp_codegen_class_is_value_type(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7)) ? ___0_key : &___0_key), SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3);
		NullCheck(L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1Invoker< bool, Il2CppFullySharedGenericAny >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, (il2cpp_codegen_class_is_value_type(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7)) ? L_1: *(void**)L_1));
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyDictionary_2_System_Collections_Generic_IDictionaryU3CTKeyU2CTValueU3E_get_Keys_mBEBC84C1F5E1B11D0450837253B41C389D74FABF_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221* L_0;
		L_0 = ((  KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221* (*) (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734*, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 9)))(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 9));
		return (RuntimeObject*)L_0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyDictionary_2_TryGetValue_m1E53DEAAC0A4FA6EA9A62FD6CAE08C28094D206B_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, Il2CppFullySharedGenericAny ___0_key, Il2CppFullySharedGenericAny* ___1_value, const RuntimeMethod* method) 
{
	const uint32_t SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3 = il2cpp_codegen_sizeof(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7));
	const Il2CppFullySharedGenericAny L_1 = alloca(SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3);
	{
		RuntimeObject* L_0 = __this->___m_dictionary;
		il2cpp_codegen_memcpy(L_1, (il2cpp_codegen_class_is_value_type(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7)) ? ___0_key : &___0_key), SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3);
		Il2CppFullySharedGenericAny* L_2 = ___1_value;
		NullCheck(L_0);
		bool L_3;
		L_3 = InterfaceFuncInvoker2Invoker< bool, Il2CppFullySharedGenericAny, Il2CppFullySharedGenericAny* >::Invoke(7, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, (il2cpp_codegen_class_is_value_type(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7)) ? L_1: *(void**)L_1), L_2);
		return L_3;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyDictionary_2_System_Collections_Generic_IDictionaryU3CTKeyU2CTValueU3E_get_Values_m48CD0FA2868BA87C697AA1271790FCFD0D38ED69_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849* L_0;
		L_0 = ((  ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849* (*) (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734*, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 11)))(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 11));
		return (RuntimeObject*)L_0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyDictionary_2_get_Item_m7C1B738861802341266E872538431A816B1507A2_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, Il2CppFullySharedGenericAny ___0_key, Il2CppFullySharedGenericAny* il2cppRetVal, const RuntimeMethod* method) 
{
	const uint32_t SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3 = il2cpp_codegen_sizeof(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7));
	const uint32_t SizeOf_TValue_t43EDFC56FE2495E1ED9690FFC4BE75C460E759B1 = il2cpp_codegen_sizeof(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 13));
	const Il2CppFullySharedGenericAny L_1 = alloca(SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3);
	const Il2CppFullySharedGenericAny L_2 = alloca(SizeOf_TValue_t43EDFC56FE2495E1ED9690FFC4BE75C460E759B1);
	{
		RuntimeObject* L_0 = __this->___m_dictionary;
		il2cpp_codegen_memcpy(L_1, (il2cpp_codegen_class_is_value_type(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7)) ? ___0_key : &___0_key), SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3);
		NullCheck(L_0);
		InterfaceActionInvoker2Invoker< Il2CppFullySharedGenericAny, Il2CppFullySharedGenericAny* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, (il2cpp_codegen_class_is_value_type(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7)) ? L_1: *(void**)L_1), (Il2CppFullySharedGenericAny*)L_2);
		il2cpp_codegen_memcpy(il2cppRetVal, L_2, SizeOf_TValue_t43EDFC56FE2495E1ED9690FFC4BE75C460E759B1);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyDictionary_2_System_Collections_Generic_IDictionaryU3CTKeyU2CTValueU3E_Add_m760232769BCF4D542ADC3675CDFB72C49999896D_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, Il2CppFullySharedGenericAny ___0_key, Il2CppFullySharedGenericAny ___1_value, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralE7AF8BCE7F42000322C784E007AAB43CA3E3D9AB)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyDictionary_2_System_Collections_Generic_IDictionaryU3CTKeyU2CTValueU3E_Remove_mD8EBB6AFBE0B504354FA2AD3C925191E6609F731_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, Il2CppFullySharedGenericAny ___0_key, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralE7AF8BCE7F42000322C784E007AAB43CA3E3D9AB)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyDictionary_2_System_Collections_Generic_IDictionaryU3CTKeyU2CTValueU3E_get_Item_m9574ECF6ECDBFB0B78285A7C8AFF03FD2B4013D6_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, Il2CppFullySharedGenericAny ___0_key, Il2CppFullySharedGenericAny* il2cppRetVal, const RuntimeMethod* method) 
{
	const uint32_t SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3 = il2cpp_codegen_sizeof(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7));
	const uint32_t SizeOf_TValue_t43EDFC56FE2495E1ED9690FFC4BE75C460E759B1 = il2cpp_codegen_sizeof(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 13));
	const Il2CppFullySharedGenericAny L_1 = alloca(SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3);
	const Il2CppFullySharedGenericAny L_2 = alloca(SizeOf_TValue_t43EDFC56FE2495E1ED9690FFC4BE75C460E759B1);
	{
		RuntimeObject* L_0 = __this->___m_dictionary;
		il2cpp_codegen_memcpy(L_1, (il2cpp_codegen_class_is_value_type(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7)) ? ___0_key : &___0_key), SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3);
		NullCheck(L_0);
		InterfaceActionInvoker2Invoker< Il2CppFullySharedGenericAny, Il2CppFullySharedGenericAny* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 0), L_0, (il2cpp_codegen_class_is_value_type(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7)) ? L_1: *(void**)L_1), (Il2CppFullySharedGenericAny*)L_2);
		il2cpp_codegen_memcpy(il2cppRetVal, L_2, SizeOf_TValue_t43EDFC56FE2495E1ED9690FFC4BE75C460E759B1);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyDictionary_2_System_Collections_Generic_IDictionaryU3CTKeyU2CTValueU3E_set_Item_m04BE92540AEBDD07DF1A30D6736F68317A8086B1_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, Il2CppFullySharedGenericAny ___0_key, Il2CppFullySharedGenericAny ___1_value, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralE7AF8BCE7F42000322C784E007AAB43CA3E3D9AB)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyDictionary_2_get_Count_m570BC218FBF8EE3D7E5551E874DF20638F397CA7_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___m_dictionary;
		NullCheck((RuntimeObject*)L_0);
		int32_t L_1;
		L_1 = InterfaceFuncInvoker0< int32_t >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 14), (RuntimeObject*)L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyDictionary_2_System_Collections_Generic_ICollectionU3CSystem_Collections_Generic_KeyValuePairU3CTKeyU2CTValueU3EU3E_Contains_m1911E89A7546D2C7F1DD67B61404C8B3D00A36EE_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669 ___0_item, const RuntimeMethod* method) 
{
	const uint32_t SizeOf_KeyValuePair_2_t0239F3881F4C8BE84CFABF0F90DFD19A583B6C95 = il2cpp_codegen_sizeof(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 16));
	const KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669 L_1 = alloca(SizeOf_KeyValuePair_2_t0239F3881F4C8BE84CFABF0F90DFD19A583B6C95);
	{
		RuntimeObject* L_0 = __this->___m_dictionary;
		il2cpp_codegen_memcpy(L_1, ___0_item, SizeOf_KeyValuePair_2_t0239F3881F4C8BE84CFABF0F90DFD19A583B6C95);
		NullCheck((RuntimeObject*)L_0);
		bool L_2;
		L_2 = InterfaceFuncInvoker1Invoker< bool, KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669 >::Invoke(4, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 14), (RuntimeObject*)L_0, L_1);
		return L_2;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyDictionary_2_System_Collections_Generic_ICollectionU3CSystem_Collections_Generic_KeyValuePairU3CTKeyU2CTValueU3EU3E_CopyTo_mF57A320EF60929F01E8B81CEA0B003EFF819CB79_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, KeyValuePair_2U5BU5D_t885F2E060B0261B18E97D336746D53BA61338F57* ___0_array, int32_t ___1_arrayIndex, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___m_dictionary;
		KeyValuePair_2U5BU5D_t885F2E060B0261B18E97D336746D53BA61338F57* L_1 = ___0_array;
		int32_t L_2 = ___1_arrayIndex;
		NullCheck((RuntimeObject*)L_0);
		InterfaceActionInvoker2< KeyValuePair_2U5BU5D_t885F2E060B0261B18E97D336746D53BA61338F57*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 14), (RuntimeObject*)L_0, L_1, L_2);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyDictionary_2_System_Collections_Generic_ICollectionU3CSystem_Collections_Generic_KeyValuePairU3CTKeyU2CTValueU3EU3E_get_IsReadOnly_m95064FB8DE29991E11D317B1112868234B687EB6_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyDictionary_2_System_Collections_Generic_ICollectionU3CSystem_Collections_Generic_KeyValuePairU3CTKeyU2CTValueU3EU3E_Add_mE36881BC770002B4BFB810CDD84B88FE8500A55F_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669 ___0_item, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralE7AF8BCE7F42000322C784E007AAB43CA3E3D9AB)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyDictionary_2_System_Collections_Generic_ICollectionU3CSystem_Collections_Generic_KeyValuePairU3CTKeyU2CTValueU3EU3E_Clear_mFB7C727CCCA77F742773A4537B99A5042C48DBF3_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralE7AF8BCE7F42000322C784E007AAB43CA3E3D9AB)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyDictionary_2_System_Collections_Generic_ICollectionU3CSystem_Collections_Generic_KeyValuePairU3CTKeyU2CTValueU3EU3E_Remove_mD21C9806294C21C66C48BBCC7124FF9F72753A08_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669 ___0_item, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralE7AF8BCE7F42000322C784E007AAB43CA3E3D9AB)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyDictionary_2_GetEnumerator_m3FFC97D7546675C2514644991A7E196D5039E5AB_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->___m_dictionary;
		NullCheck((RuntimeObject*)L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 19), (RuntimeObject*)L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyDictionary_2_System_Collections_IEnumerable_GetEnumerator_mE28E564A8649570EA9A1CE7107DF7E5FE7A21EFD_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&IEnumerable_t6331596D5DD37C462B1B8D49CF6B319B00AB7131_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	{
		RuntimeObject* L_0 = __this->___m_dictionary;
		NullCheck((RuntimeObject*)L_0);
		RuntimeObject* L_1;
		L_1 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, IEnumerable_t6331596D5DD37C462B1B8D49CF6B319B00AB7131_il2cpp_TypeInfo_var, (RuntimeObject*)L_0);
		return L_1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyDictionary_2_IsCompatibleKey_m4D74774D18B06ACA450E3D355EF8398353B677EE_fshared (RuntimeObject* ___0_key, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	{
		RuntimeObject* L_0 = ___0_key;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		ArgumentNullException_t327031E412FAB2351B0022DD5DAD47E67E597129* L_1 = (ArgumentNullException_t327031E412FAB2351B0022DD5DAD47E67E597129*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArgumentNullException_t327031E412FAB2351B0022DD5DAD47E67E597129_il2cpp_TypeInfo_var)));
		ArgumentNullException__ctor_m444AE141157E333844FC1A9500224C2F9FD24F4B(L_1, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralE7D028CCE3B6E7B61AE2C752D7AE970DA04AB7C6)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_1, method);
	}

IL_000e:
	{
		RuntimeObject* L_2 = ___0_key;
		return (bool)((!(((RuntimeObject*)(RuntimeObject*)((RuntimeObject*)IsInst((RuntimeObject*)L_2, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7)))) <= ((RuntimeObject*)(RuntimeObject*)NULL)))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyDictionary_2_System_Collections_IDictionary_Add_mFD7ED5C86355FB8D05C1209AFBB8A79B6E0BA797_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, RuntimeObject* ___0_key, RuntimeObject* ___1_value, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralE7AF8BCE7F42000322C784E007AAB43CA3E3D9AB)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyDictionary_2_System_Collections_IDictionary_Clear_mFAE5622F79BFAADCDA0C21C758D1B6AA49D32017_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralE7AF8BCE7F42000322C784E007AAB43CA3E3D9AB)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyDictionary_2_System_Collections_IDictionary_Contains_m24123A7F88C2C800C9037836C4773B3A18A54275_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, RuntimeObject* ___0_key, const RuntimeMethod* method) 
{
	const uint32_t SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3 = il2cpp_codegen_sizeof(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7));
	const Il2CppFullySharedGenericAny L_3 = alloca(SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3);
	{
		RuntimeObject* L_0 = ___0_key;
		bool L_1;
		L_1 = ((  bool (*) (RuntimeObject*, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 21)))(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 21));
		if (!L_1)
		{
			goto IL_0015;
		}
	}
	{
		RuntimeObject* L_2 = ___0_key;
		void* L_4 = UnBox_Any(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7), L_3);
		bool L_5;
		L_5 = InvokerFuncInvoker1< bool, Il2CppFullySharedGenericAny >::Invoke(il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 22)), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 22), __this, (il2cpp_codegen_class_is_value_type(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7)) ? (((Il2CppFullySharedGenericAny)(Il2CppFullySharedGenericAny*)L_4)): *(void**)(((Il2CppFullySharedGenericAny)(Il2CppFullySharedGenericAny*)L_4))));
		return L_5;
	}

IL_0015:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyDictionary_2_System_Collections_IDictionary_GetEnumerator_m0285CEE9474EAA483097CF2480942BC24E6E3BF7_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&IDictionary_t6D03155AF1FA9083817AA5B6AD7DEEACC26AB220_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	RuntimeObject* V_0 = NULL;
	{
		RuntimeObject* L_0 = __this->___m_dictionary;
		V_0 = ((RuntimeObject*)IsInst((RuntimeObject*)L_0, IDictionary_t6D03155AF1FA9083817AA5B6AD7DEEACC26AB220_il2cpp_TypeInfo_var));
		RuntimeObject* L_1 = V_0;
		if (!L_1)
		{
			goto IL_0016;
		}
	}
	{
		RuntimeObject* L_2 = V_0;
		NullCheck(L_2);
		RuntimeObject* L_3;
		L_3 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(8, IDictionary_t6D03155AF1FA9083817AA5B6AD7DEEACC26AB220_il2cpp_TypeInfo_var, L_2);
		return L_3;
	}

IL_0016:
	{
		RuntimeObject* L_4 = __this->___m_dictionary;
		DictionaryEnumerator_tA07B53C91CCF243B3DDF48825CD4F71A6835CD77 L_5;
		memset((&L_5), 0, sizeof(L_5));
		DictionaryEnumerator__ctor_mA1A62AF5ED8AB1B514BBAAAEA9BB3D081C3AA4ED((&L_5), L_4, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 23));
		DictionaryEnumerator_tA07B53C91CCF243B3DDF48825CD4F71A6835CD77 L_6 = L_5;
		RuntimeObject* L_7 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 24), &L_6);
		return (RuntimeObject*)L_7;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyDictionary_2_System_Collections_IDictionary_get_IsReadOnly_mCADBA490FFA90323B8FEDC38CD78141C54CC10DF_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		return (bool)1;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyDictionary_2_System_Collections_IDictionary_get_Keys_m203F3078EE234F53D90604EFDC9609D2B90B219B_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221* L_0;
		L_0 = ((  KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221* (*) (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734*, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 9)))(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 9));
		return (RuntimeObject*)L_0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyDictionary_2_System_Collections_IDictionary_Remove_mCC94C51FD44D29ACE9EBBA8BF55A9BED1EE617D8_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, RuntimeObject* ___0_key, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralE7AF8BCE7F42000322C784E007AAB43CA3E3D9AB)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyDictionary_2_System_Collections_IDictionary_get_Values_m4592B94799170DC13E0F5BDD221769C548BCD680_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849* L_0;
		L_0 = ((  ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849* (*) (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734*, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 11)))(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 11));
		return (RuntimeObject*)L_0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyDictionary_2_System_Collections_IDictionary_get_Item_m5EB78E7B173088D4B73585597F8C1AA9A61E2720_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, RuntimeObject* ___0_key, const RuntimeMethod* method) 
{
	const uint32_t SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3 = il2cpp_codegen_sizeof(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7));
	const Il2CppFullySharedGenericAny L_3 = alloca(SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3);
	const uint32_t SizeOf_TValue_t43EDFC56FE2495E1ED9690FFC4BE75C460E759B1 = il2cpp_codegen_sizeof(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 13));
	const Il2CppFullySharedGenericAny L_5 = alloca(SizeOf_TValue_t43EDFC56FE2495E1ED9690FFC4BE75C460E759B1);
	{
		RuntimeObject* L_0 = ___0_key;
		bool L_1;
		L_1 = ((  bool (*) (RuntimeObject*, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 21)))(L_0, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 21));
		if (!L_1)
		{
			goto IL_001a;
		}
	}
	{
		RuntimeObject* L_2 = ___0_key;
		void* L_4 = UnBox_Any(L_2, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7), L_3);
		InvokerActionInvoker2< Il2CppFullySharedGenericAny, Il2CppFullySharedGenericAny* >::Invoke(il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 25)), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 25), __this, (il2cpp_codegen_class_is_value_type(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7)) ? (((Il2CppFullySharedGenericAny)(Il2CppFullySharedGenericAny*)L_4)): *(void**)(((Il2CppFullySharedGenericAny)(Il2CppFullySharedGenericAny*)L_4))), (Il2CppFullySharedGenericAny*)L_5);
		RuntimeObject* L_6 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 13), L_5);
		return L_6;
	}

IL_001a:
	{
		return NULL;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyDictionary_2_System_Collections_IDictionary_set_Item_mCFEB082FB514C3C58C6C908B833CC7FF5B5A6D6A_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, RuntimeObject* ___0_key, RuntimeObject* ___1_value, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralE7AF8BCE7F42000322C784E007AAB43CA3E3D9AB)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyDictionary_2_System_Collections_ICollection_CopyTo_mB747FA5969557062AD3E00EF54BC5185C08504E7_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, RuntimeArray* ___0_array, int32_t ___1_index, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&DictionaryEntryU5BU5D_t410156653E754D17B5E1161CC6CF565103B63533_il2cpp_TypeInfo_var);
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&IDisposable_t030E0496B4E0E4E4F086825007979AF51F7248C5_il2cpp_TypeInfo_var);
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&IEnumerator_t7B609C2FFA6EB5167D9C62A0C32A21DE2F666DAA_il2cpp_TypeInfo_var);
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	const uint32_t SizeOf_KeyValuePair_2_t0239F3881F4C8BE84CFABF0F90DFD19A583B6C95 = il2cpp_codegen_sizeof(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 16));
	const uint32_t SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3 = il2cpp_codegen_sizeof(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7));
	const uint32_t SizeOf_TValue_t43EDFC56FE2495E1ED9690FFC4BE75C460E759B1 = il2cpp_codegen_sizeof(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 13));
	const Il2CppFullySharedGenericAny L_34 = alloca(SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3);
	const Il2CppFullySharedGenericAny L_53 = L_34;
	const Il2CppFullySharedGenericAny L_55 = alloca(SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3);
	const Il2CppFullySharedGenericAny L_36 = alloca(SizeOf_TValue_t43EDFC56FE2495E1ED9690FFC4BE75C460E759B1);
	const Il2CppFullySharedGenericAny L_54 = L_36;
	const Il2CppFullySharedGenericAny L_56 = alloca(SizeOf_TValue_t43EDFC56FE2495E1ED9690FFC4BE75C460E759B1);
	const KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669 L_30 = alloca(SizeOf_KeyValuePair_2_t0239F3881F4C8BE84CFABF0F90DFD19A583B6C95);
	const KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669 L_49 = L_30;
	const KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669 L_57 = alloca(SizeOf_KeyValuePair_2_t0239F3881F4C8BE84CFABF0F90DFD19A583B6C95);
	KeyValuePair_2U5BU5D_t885F2E060B0261B18E97D336746D53BA61338F57* V_0 = NULL;
	DictionaryEntryU5BU5D_t410156653E754D17B5E1161CC6CF565103B63533* V_1 = NULL;
	RuntimeObject* V_2 = NULL;
	KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669 V_3 = alloca(SizeOf_KeyValuePair_2_t0239F3881F4C8BE84CFABF0F90DFD19A583B6C95);
	memset(V_3, 0, SizeOf_KeyValuePair_2_t0239F3881F4C8BE84CFABF0F90DFD19A583B6C95);
	ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* V_4 = NULL;
	KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669 V_5 = alloca(SizeOf_KeyValuePair_2_t0239F3881F4C8BE84CFABF0F90DFD19A583B6C95);
	memset(V_5, 0, SizeOf_KeyValuePair_2_t0239F3881F4C8BE84CFABF0F90DFD19A583B6C95);
	il2cpp::utils::ExceptionSupportStack<RuntimeObject*, 1> __active_exceptions;
	{
		RuntimeArray* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		ArgumentNullException_t327031E412FAB2351B0022DD5DAD47E67E597129* L_1 = (ArgumentNullException_t327031E412FAB2351B0022DD5DAD47E67E597129*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArgumentNullException_t327031E412FAB2351B0022DD5DAD47E67E597129_il2cpp_TypeInfo_var)));
		ArgumentNullException__ctor_m444AE141157E333844FC1A9500224C2F9FD24F4B(L_1, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralB829404B947F7E1629A30B5E953A49EB21CCD2ED)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_1, method);
	}

IL_000e:
	{
		RuntimeArray* L_2 = ___0_array;
		NullCheck(L_2);
		int32_t L_3;
		L_3 = il2cpp_codegen_array_get_rank(L_2);
		if ((((int32_t)L_3) == ((int32_t)1)))
		{
			goto IL_0022;
		}
	}
	{
		ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263* L_4 = (ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263_il2cpp_TypeInfo_var)));
		ArgumentException__ctor_m026938A67AF9D36BB7ED27F80425D7194B514465(L_4, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral967D403A541A1026A83D548E5AD5CA800AD4EFB5)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_4, method);
	}

IL_0022:
	{
		RuntimeArray* L_5 = ___0_array;
		NullCheck(L_5);
		int32_t L_6;
		L_6 = Array_GetLowerBound_m4FB0601E2E8A6304A42E3FC400576DF7B0F084BC(L_5, 0, NULL);
		if (!L_6)
		{
			goto IL_0036;
		}
	}
	{
		ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263* L_7 = (ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263_il2cpp_TypeInfo_var)));
		ArgumentException__ctor_m026938A67AF9D36BB7ED27F80425D7194B514465(L_7, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral6195D7DA68D16D4985AD1A1B4FD2841A43CDDE70)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_7, method);
	}

IL_0036:
	{
		int32_t L_8 = ___1_index;
		if ((((int32_t)L_8) < ((int32_t)0)))
		{
			goto IL_0043;
		}
	}
	{
		int32_t L_9 = ___1_index;
		RuntimeArray* L_10 = ___0_array;
		NullCheck(L_10);
		int32_t L_11;
		L_11 = il2cpp_codegen_array_get_length(L_10);
		if ((((int32_t)L_9) <= ((int32_t)L_11)))
		{
			goto IL_0053;
		}
	}

IL_0043:
	{
		ArgumentOutOfRangeException_tEA2822DAF62B10EEED00E0E3A341D4BAF78CF85F* L_12 = (ArgumentOutOfRangeException_tEA2822DAF62B10EEED00E0E3A341D4BAF78CF85F*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArgumentOutOfRangeException_tEA2822DAF62B10EEED00E0E3A341D4BAF78CF85F_il2cpp_TypeInfo_var)));
		ArgumentOutOfRangeException__ctor_mE5B2755F0BEA043CACF915D5CE140859EE58FA66(L_12, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral2B6D6F48C27C60C3B55391AB377D9DC8F5639AA1)), ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral38E3DBC7FC353425EF3A98DC8DAC6689AF5FD1BE)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_12, method);
	}

IL_0053:
	{
		RuntimeArray* L_13 = ___0_array;
		NullCheck(L_13);
		int32_t L_14;
		L_14 = il2cpp_codegen_array_get_length(L_13);
		int32_t L_15 = ___1_index;
		int32_t L_16;
		L_16 = ((  int32_t (*) (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734*, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 26)))(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 26));
		if ((((int32_t)((int32_t)il2cpp_codegen_subtract(L_14, L_15))) >= ((int32_t)L_16)))
		{
			goto IL_006e;
		}
	}
	{
		ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263* L_17 = (ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263_il2cpp_TypeInfo_var)));
		ArgumentException__ctor_m026938A67AF9D36BB7ED27F80425D7194B514465(L_17, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral3ECE023333DCF45DE7B1FEAFFE30E295210DDD9B)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_17, method);
	}

IL_006e:
	{
		RuntimeArray* L_18 = ___0_array;
		V_0 = ((KeyValuePair_2U5BU5D_t885F2E060B0261B18E97D336746D53BA61338F57*)IsInstSealed((RuntimeObject*)L_18, il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 27)));
		KeyValuePair_2U5BU5D_t885F2E060B0261B18E97D336746D53BA61338F57* L_19 = V_0;
		if (!L_19)
		{
			goto IL_0086;
		}
	}
	{
		RuntimeObject* L_20 = __this->___m_dictionary;
		KeyValuePair_2U5BU5D_t885F2E060B0261B18E97D336746D53BA61338F57* L_21 = V_0;
		int32_t L_22 = ___1_index;
		NullCheck((RuntimeObject*)L_20);
		InterfaceActionInvoker2< KeyValuePair_2U5BU5D_t885F2E060B0261B18E97D336746D53BA61338F57*, int32_t >::Invoke(5, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 14), (RuntimeObject*)L_20, L_21, L_22);
		return;
	}

IL_0086:
	{
		RuntimeArray* L_23 = ___0_array;
		V_1 = ((DictionaryEntryU5BU5D_t410156653E754D17B5E1161CC6CF565103B63533*)IsInstSealed((RuntimeObject*)L_23, DictionaryEntryU5BU5D_t410156653E754D17B5E1161CC6CF565103B63533_il2cpp_TypeInfo_var));
		DictionaryEntryU5BU5D_t410156653E754D17B5E1161CC6CF565103B63533* L_24 = V_1;
		if (!L_24)
		{
			goto IL_00e2;
		}
	}
	{
		RuntimeObject* L_25 = __this->___m_dictionary;
		NullCheck((RuntimeObject*)L_25);
		RuntimeObject* L_26;
		L_26 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 19), (RuntimeObject*)L_25);
		V_2 = L_26;
	}
	{
		auto __finallyBlock = il2cpp::utils::Finally([&]
		{

FINALLY_00d8:
			{
				{
					RuntimeObject* L_27 = V_2;
					if (!L_27)
					{
						goto IL_00e1;
					}
				}
				{
					RuntimeObject* L_28 = V_2;
					NullCheck((RuntimeObject*)L_28);
					InterfaceActionInvoker0::Invoke(0, IDisposable_t030E0496B4E0E4E4F086825007979AF51F7248C5_il2cpp_TypeInfo_var, (RuntimeObject*)L_28);
				}

IL_00e1:
				{
					return;
				}
			}
		});
		try
		{
			{
				goto IL_00ce_1;
			}

IL_009e_1:
			{
				RuntimeObject* L_29 = V_2;
				NullCheck(L_29);
				InterfaceActionInvoker1Invoker< KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 28), L_29, (KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669*)L_30);
				il2cpp_codegen_memcpy(V_3, L_30, SizeOf_KeyValuePair_2_t0239F3881F4C8BE84CFABF0F90DFD19A583B6C95);
				DictionaryEntryU5BU5D_t410156653E754D17B5E1161CC6CF565103B63533* L_31 = V_1;
				int32_t L_32 = ___1_index;
				int32_t L_33 = L_32;
				___1_index = ((int32_t)il2cpp_codegen_add(L_33, 1));
				InvokerActionInvoker1< Il2CppFullySharedGenericAny* >::Invoke(il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 30)), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 30), (KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669*)V_3, (Il2CppFullySharedGenericAny*)L_34);
				RuntimeObject* L_35 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7), L_34);
				InvokerActionInvoker1< Il2CppFullySharedGenericAny* >::Invoke(il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 31)), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 31), (KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669*)V_3, (Il2CppFullySharedGenericAny*)L_36);
				RuntimeObject* L_37 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 13), L_36);
				DictionaryEntry_t171080F37B311C25AA9E75888F9C9D703FA721BB L_38;
				memset((&L_38), 0, sizeof(L_38));
				DictionaryEntry__ctor_m2768353E53A75C4860E34B37DAF1342120C5D1EA((&L_38), L_35, L_37, NULL);
				NullCheck(L_31);
				(L_31)->SetAt(static_cast<il2cpp_array_size_t>(L_33), (DictionaryEntry_t171080F37B311C25AA9E75888F9C9D703FA721BB)L_38);
			}

IL_00ce_1:
			{
				RuntimeObject* L_39 = V_2;
				NullCheck((RuntimeObject*)L_39);
				bool L_40;
				L_40 = InterfaceFuncInvoker0< bool >::Invoke(0, IEnumerator_t7B609C2FFA6EB5167D9C62A0C32A21DE2F666DAA_il2cpp_TypeInfo_var, (RuntimeObject*)L_39);
				if (L_40)
				{
					goto IL_009e_1;
				}
			}
			{
				goto IL_0153;
			}
		}
		catch(Il2CppNativeThreadAbortException&)
		{
			__finallyBlock.SetNativeThreadAbortOccurred();
		}
		catch(Il2CppExceptionWrapper& e)
		{
			__finallyBlock.StoreException(e.ex);
		}
	}

IL_00e2:
	{
		RuntimeArray* L_41 = ___0_array;
		V_4 = ((ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918*)IsInst((RuntimeObject*)L_41, ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918_il2cpp_TypeInfo_var));
		ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_42 = V_4;
		if (L_42)
		{
			goto IL_00f9;
		}
	}
	{
		ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263* L_43 = (ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263_il2cpp_TypeInfo_var)));
		ArgumentException__ctor_m026938A67AF9D36BB7ED27F80425D7194B514465(L_43, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralBD0381A992FDF4F7DA60E5D83689FE7FF6309CB8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_43, method);
	}

IL_00f9:
	{
	}
	try
	{
		{
			RuntimeObject* L_44 = __this->___m_dictionary;
			NullCheck((RuntimeObject*)L_44);
			RuntimeObject* L_45;
			L_45 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 19), (RuntimeObject*)L_44);
			V_2 = L_45;
		}
		{
			auto __finallyBlock = il2cpp::utils::Finally([&]
			{

FINALLY_013b_1:
				{
					{
						RuntimeObject* L_46 = V_2;
						if (!L_46)
						{
							goto IL_0144_1;
						}
					}
					{
						RuntimeObject* L_47 = V_2;
						NullCheck((RuntimeObject*)L_47);
						InterfaceActionInvoker0::Invoke(0, IDisposable_t030E0496B4E0E4E4F086825007979AF51F7248C5_il2cpp_TypeInfo_var, (RuntimeObject*)L_47);
					}

IL_0144_1:
					{
						return;
					}
				}
			});
			try
			{
				{
					goto IL_0131_2;
				}

IL_0108_2:
				{
					RuntimeObject* L_48 = V_2;
					NullCheck(L_48);
					InterfaceActionInvoker1Invoker< KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669* >::Invoke(0, il2cpp_rgctx_data_init(il2cpp_codegen_method_rgctx(method), 28), L_48, (KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669*)L_49);
					il2cpp_codegen_memcpy(V_5, L_49, SizeOf_KeyValuePair_2_t0239F3881F4C8BE84CFABF0F90DFD19A583B6C95);
					ObjectU5BU5D_t8061030B0A12A55D5AD8652A20C922FE99450918* L_50 = V_4;
					int32_t L_51 = ___1_index;
					int32_t L_52 = L_51;
					___1_index = ((int32_t)il2cpp_codegen_add(L_52, 1));
					InvokerActionInvoker1< Il2CppFullySharedGenericAny* >::Invoke(il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 30)), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 30), (KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669*)V_5, (Il2CppFullySharedGenericAny*)L_53);
					InvokerActionInvoker1< Il2CppFullySharedGenericAny* >::Invoke(il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 31)), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 31), (KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669*)V_5, (Il2CppFullySharedGenericAny*)L_54);
					memset(L_57, 0, SizeOf_KeyValuePair_2_t0239F3881F4C8BE84CFABF0F90DFD19A583B6C95);
					KeyValuePair_2__ctor_mD82E516936D2BDE6D46C8C45270250647986231E((KeyValuePair_2_t28EF90BF7804CE5D7F99A364266351E7DC652669*)L_57, (il2cpp_codegen_class_is_value_type(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 7)) ? il2cpp_codegen_memcpy(L_55, L_53, SizeOf_TKey_t6CF24411882409C9C594E33E1DFE77DBD6BBA1B3): *(void**)L_53), (il2cpp_codegen_class_is_value_type(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 13)) ? il2cpp_codegen_memcpy(L_56, L_54, SizeOf_TValue_t43EDFC56FE2495E1ED9690FFC4BE75C460E759B1): *(void**)L_54), il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 32));
					RuntimeObject* L_58 = Box(il2cpp_rgctx_data(il2cpp_codegen_method_rgctx(method), 16), L_57);
					NullCheck(L_50);
					ArrayElementTypeCheck (L_50, L_58);
					(L_50)->SetAt(static_cast<il2cpp_array_size_t>(L_52), (RuntimeObject*)L_58);
				}

IL_0131_2:
				{
					RuntimeObject* L_59 = V_2;
					NullCheck((RuntimeObject*)L_59);
					bool L_60;
					L_60 = InterfaceFuncInvoker0< bool >::Invoke(0, IEnumerator_t7B609C2FFA6EB5167D9C62A0C32A21DE2F666DAA_il2cpp_TypeInfo_var, (RuntimeObject*)L_59);
					if (L_60)
					{
						goto IL_0108_2;
					}
				}
				{
					goto IL_0145_1;
				}
			}
			catch(Il2CppNativeThreadAbortException&)
			{
				__finallyBlock.SetNativeThreadAbortOccurred();
			}
			catch(Il2CppExceptionWrapper& e)
			{
				__finallyBlock.StoreException(e.ex);
			}
		}

IL_0145_1:
		{
			goto IL_0153;
		}
	}
	catch(Il2CppExceptionWrapper& e)
	{
		if(il2cpp_codegen_class_is_assignable_from (((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1_il2cpp_TypeInfo_var)), il2cpp_codegen_object_class(e.ex)))
		{
			IL2CPP_PUSH_ACTIVE_EXCEPTION(e.ex);
			goto CATCH_0147;
		}
		throw e;
	}

CATCH_0147:
	{
		ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1* L_61 = ((ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*)IL2CPP_GET_ACTIVE_EXCEPTION(ArrayTypeMismatchException_t95F1723A5A166E62D3FBEF9734DEFBF61594F8F1*));;
		ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263* L_62 = (ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&ArgumentException_tAD90411542A20A9C72D5CDA3A84181D8B947A263_il2cpp_TypeInfo_var)));
		ArgumentException__ctor_m026938A67AF9D36BB7ED27F80425D7194B514465(L_62, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralBD0381A992FDF4F7DA60E5D83689FE7FF6309CB8)), NULL);
		IL2CPP_POP_ACTIVE_EXCEPTION(Exception_t*);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_62, method);
	}

IL_0153:
	{
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyDictionary_2_System_Collections_ICollection_get_IsSynchronized_m775918D51697D5404B898ACB89208A1498A46CB3_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyDictionary_2_System_Collections_ICollection_get_SyncRoot_mE06D92F6EEC7E9C3245A31B7B75DE348212F59F7_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&ICollection_t37E7B9DC5B4EF41D190D607F92835BF1171C0E8E_il2cpp_TypeInfo_var);
		s_Il2CppMethodInitialized = true;
	}
	RuntimeObject* V_0 = NULL;
	{
		RuntimeObject* L_0 = __this->____syncRoot;
		if (L_0)
		{
			goto IL_0037;
		}
	}
	{
		RuntimeObject* L_1 = __this->___m_dictionary;
		V_0 = ((RuntimeObject*)IsInst((RuntimeObject*)L_1, ICollection_t37E7B9DC5B4EF41D190D607F92835BF1171C0E8E_il2cpp_TypeInfo_var));
		RuntimeObject* L_2 = V_0;
		if (!L_2)
		{
			goto IL_0025;
		}
	}
	{
		RuntimeObject* L_3 = V_0;
		NullCheck(L_3);
		RuntimeObject* L_4;
		L_4 = InterfaceFuncInvoker0< RuntimeObject* >::Invoke(2, ICollection_t37E7B9DC5B4EF41D190D607F92835BF1171C0E8E_il2cpp_TypeInfo_var, L_3);
		__this->____syncRoot = L_4;
		Il2CppCodeGenWriteBarrier((void**)(&__this->____syncRoot), (void*)L_4);
		goto IL_0037;
	}

IL_0025:
	{
		RuntimeObject** L_5 = (RuntimeObject**)(&__this->____syncRoot);
		RuntimeObject* L_6 = (RuntimeObject*)il2cpp_codegen_object_new(RuntimeObject_il2cpp_TypeInfo_var);
		Object__ctor_mE837C6B9FA8C6D5D109F4B2EC885D79919AC0EA2(L_6, NULL);
		RuntimeObject* L_7;
		L_7 = il2cpp_intrinsic_interlocked_compare_exchange(L_5, L_6, NULL);
	}

IL_0037:
	{
		RuntimeObject* L_8 = __this->____syncRoot;
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyDictionary_2_System_Collections_Generic_IReadOnlyDictionaryU3CTKeyU2CTValueU3E_get_Keys_m5517F5B43EFB878E6A1DB24A9DA5C2B0A6C2FB65_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221* L_0;
		L_0 = ((  KeyCollection_t77347D5E6080A99487985EFA49C429DAC62A4221* (*) (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734*, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 9)))(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 9));
		return (RuntimeObject*)L_0;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyDictionary_2_System_Collections_Generic_IReadOnlyDictionaryU3CTKeyU2CTValueU3E_get_Values_mFD4DE52E42982BE1C72AB6314736968DEA611E37_fshared (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734* __this, const RuntimeMethod* method) 
{
	{
		ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849* L_0;
		L_0 = ((  ValueCollection_tBD303C20E55147B0A354B6AD8C7779ABBC77D849* (*) (ReadOnlyDictionary_2_tC043257AB947D9A94D4AF6916DD67B7C30D3F734*, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 11)))(__this, il2cpp_rgctx_method(il2cpp_codegen_method_rgctx(method), 11));
		return (RuntimeObject*)L_0;
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlyMemory_1_ToString_m0C4DF727B39C613F84AC56D6FDAF7ACFF9E39720 (ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral958BF5561D89C9A90653416FCB65BBE72DADDE1E);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	String_t* V_0 = NULL;
	ReadOnlySpan_1_tA850A6C0E88ABBA37646A078ACBC24D6D5FD9B4D V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_0058;
	}

IL_0058:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 0)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = ((int32_t)(L_3&((int32_t)2147483647LL)));
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral958BF5561D89C9A90653416FCB65BBE72DADDE1E, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C  String_t* ReadOnlyMemory_1_ToString_m0C4DF727B39C613F84AC56D6FDAF7ACFF9E39720_AdjustorThunk (RuntimeObject* __this, const RuntimeMethod* method)
{
	ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399* _thisAdjusted;
	_thisAdjusted = il2cpp_codegen_get_raw_data<ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399>(__this);
	String_t* _returnValue;
	_returnValue = ReadOnlyMemory_1_ToString_m0C4DF727B39C613F84AC56D6FDAF7ACFF9E39720(_thisAdjusted, method);
	return _returnValue;
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tA850A6C0E88ABBA37646A078ACBC24D6D5FD9B4D ReadOnlyMemory_1_get_Span_mA087C8160638E6581A03C1BDAF2803AC88834762 (ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305 V_0;
	memset((&V_0), 0, sizeof(V_0));
	String_t* V_1 = NULL;
	ReadOnlySpan_1_tA850A6C0E88ABBA37646A078ACBC24D6D5FD9B4D V_2;
	memset((&V_2), 0, sizeof(V_2));
	{
		int32_t L_0 = __this->____index;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_0039;
		}
	}
	{
		RuntimeObject* L_1 = __this->____object;
		NullCheck(((MemoryManager_1_tB90442C8E0A1B9C0F8A3B603FD50501A1BADAC6E*)CastclassClass((RuntimeObject*)L_1, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))));
		Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305 L_2;
		L_2 = VirtualFuncInvoker0< Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305 >::Invoke(4, ((MemoryManager_1_tB90442C8E0A1B9C0F8A3B603FD50501A1BADAC6E*)CastclassClass((RuntimeObject*)L_1, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))));
		V_0 = L_2;
		int32_t L_3 = __this->____index;
		int32_t L_4 = __this->____length;
		Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305 L_5;
		L_5 = Span_1_Slice_m9D8BA8245B8DC9BFB4A4164759CBAAEAD1318CD6_inline((&V_0), ((int32_t)(L_3&((int32_t)2147483647LL))), L_4, NULL);
		ReadOnlySpan_1_tA850A6C0E88ABBA37646A078ACBC24D6D5FD9B4D L_6;
		L_6 = Span_1_op_Implicit_mD249188242C0C9D3192A31E9F7FA74C683F05B84(L_5, NULL);
		return L_6;
	}

IL_0039:
	{
		goto IL_008e;
	}

IL_008e:
	{
		RuntimeObject* L_7 = __this->____object;
		if (!L_7)
		{
			goto IL_00b9;
		}
	}
	{
		RuntimeObject* L_8 = __this->____object;
		int32_t L_9 = __this->____index;
		int32_t L_10 = __this->____length;
		ReadOnlySpan_1_tA850A6C0E88ABBA37646A078ACBC24D6D5FD9B4D L_11;
		memset((&L_11), 0, sizeof(L_11));
		ReadOnlySpan_1__ctor_m7B5C2765879EA5E8D1617D834CC465A39540A913_inline((&L_11), ((ByteU5BU5D_tA6237BF417AE52AD70CFB4EF24A7A82613DF9031*)Castclass((RuntimeObject*)L_8, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 9))), L_9, ((int32_t)(L_10&((int32_t)2147483647LL))), NULL);
		return L_11;
	}

IL_00b9:
	{
		il2cpp_codegen_initobj((&V_2), sizeof(ReadOnlySpan_1_tA850A6C0E88ABBA37646A078ACBC24D6D5FD9B4D));
		ReadOnlySpan_1_tA850A6C0E88ABBA37646A078ACBC24D6D5FD9B4D L_12 = V_2;
		return L_12;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyMemory_1_Equals_mD0C4947B91FD3864C476B6CA8BA929A6F5B01175 (ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399 V_0;
	memset((&V_0), 0, sizeof(V_0));
	Memory_1_tB7CEF4416F5014E364267478CEF016A4AC5C0036 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		RuntimeObject* L_0 = ___0_obj;
		if (!((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 11))))
		{
			goto IL_0017;
		}
	}
	{
		RuntimeObject* L_1 = ___0_obj;
		V_0 = ((*(ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399*)UnBox(L_1, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 11))));
		ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399 L_2 = V_0;
		bool L_3;
		L_3 = ReadOnlyMemory_1_Equals_mC3969DE0744A246E0576FEDE51191A0D3F5F69A9(__this, L_2, NULL);
		return L_3;
	}

IL_0017:
	{
		RuntimeObject* L_4 = ___0_obj;
		if (!((RuntimeObject*)IsInstSealed((RuntimeObject*)L_4, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 13))))
		{
			goto IL_0033;
		}
	}
	{
		RuntimeObject* L_5 = ___0_obj;
		V_1 = ((*(Memory_1_tB7CEF4416F5014E364267478CEF016A4AC5C0036*)UnBox(L_5, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 13))));
		Memory_1_tB7CEF4416F5014E364267478CEF016A4AC5C0036 L_6 = V_1;
		ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399 L_7;
		L_7 = Memory_1_op_Implicit_m7B80A71310A3EA9F99CB1774CAFED254811599CD(L_6, NULL);
		bool L_8;
		L_8 = ReadOnlyMemory_1_Equals_mC3969DE0744A246E0576FEDE51191A0D3F5F69A9(__this, L_7, NULL);
		return L_8;
	}

IL_0033:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C  bool ReadOnlyMemory_1_Equals_mD0C4947B91FD3864C476B6CA8BA929A6F5B01175_AdjustorThunk (RuntimeObject* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method)
{
	ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399* _thisAdjusted;
	_thisAdjusted = il2cpp_codegen_get_raw_data<ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399>(__this);
	bool _returnValue;
	_returnValue = ReadOnlyMemory_1_Equals_mD0C4947B91FD3864C476B6CA8BA929A6F5B01175(_thisAdjusted, ___0_obj, method);
	return _returnValue;
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyMemory_1_GetHashCode_mE47597BBDBFFBC9185DE65261A7388207854ADE6 (ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399* __this, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->____object;
		if (L_0)
		{
			goto IL_000a;
		}
	}
	{
		return 0;
	}

IL_000a:
	{
		RuntimeObject* L_1 = __this->____object;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = VirtualFuncInvoker0< int32_t >::Invoke(2, L_1);
		int32_t* L_3 = (int32_t*)(&__this->____index);
		int32_t L_4;
		L_4 = Int32_GetHashCode_m253D60FF7527A483E91004B7A2366F13E225E295(L_3, NULL);
		int32_t* L_5 = (int32_t*)(&__this->____length);
		int32_t L_6;
		L_6 = Int32_GetHashCode_m253D60FF7527A483E91004B7A2366F13E225E295(L_5, NULL);
		int32_t L_7;
		L_7 = ReadOnlyMemory_1_CombineHashCodes_mC20EA69C2706DE824529A0506BD45837E26C6980(L_2, L_4, L_6, NULL);
		return L_7;
	}
}
IL2CPP_EXTERN_C  int32_t ReadOnlyMemory_1_GetHashCode_mE47597BBDBFFBC9185DE65261A7388207854ADE6_AdjustorThunk (RuntimeObject* __this, const RuntimeMethod* method)
{
	ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399* _thisAdjusted;
	_thisAdjusted = il2cpp_codegen_get_raw_data<ReadOnlyMemory_1_t63F301BF893B0AB689953D86A641168CA66D2399>(__this);
	int32_t _returnValue;
	_returnValue = ReadOnlyMemory_1_GetHashCode_mE47597BBDBFFBC9185DE65261A7388207854ADE6(_thisAdjusted, method);
	return _returnValue;
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyMemory_1_CombineHashCodes_mC20EA69C2706DE824529A0506BD45837E26C6980 (int32_t ___0_h1, int32_t ___1_h2, int32_t ___2_h3, const RuntimeMethod* method) 
{
	{
		int32_t L_0 = ___0_h1;
		int32_t L_1 = ___1_h2;
		int32_t L_2;
		L_2 = ReadOnlyMemory_1_CombineHashCodes_mAD75C6BDDB231C42D8A846F50E2B081E244108DA(L_0, L_1, NULL);
		int32_t L_3 = ___2_h3;
		int32_t L_4;
		L_4 = ReadOnlyMemory_1_CombineHashCodes_mAD75C6BDDB231C42D8A846F50E2B081E244108DA(L_2, L_3, NULL);
		return L_4;
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyMemory_1__ctor_m1FD19CA8A2CB8A92DC095EE34D414ADE2FD39A12_fshared (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, __Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		__Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		__Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		__Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		__Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC* L_10 = ___0_array;
		__this->____object = (RuntimeObject*)L_10;
		Il2CppCodeGenWriteBarrier((void**)(&__this->____object), (void*)(RuntimeObject*)L_10);
		int32_t L_11 = ___1_start;
		__this->____index = L_11;
		int32_t L_12 = ___2_length;
		__this->____length = L_12;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyMemory_1_get_Length_m65A4E9056707DCDBB66443924288D7E0BA7D0074_fshared (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, const RuntimeMethod* method) 
{
	{
		int32_t L_0 = __this->____length;
		return ((int32_t)(L_0&((int32_t)2147483647LL)));
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlyMemory_1_ToString_m1AB8B8725FFC7144748E59C73875E2C6822E2321_fshared (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral958BF5561D89C9A90653416FCB65BBE72DADDE1E);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	String_t* V_0 = NULL;
	ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		bool L_0 = (Char_t521A6F19B456D956AF452D926C32709DC03D6B17_il2cpp_TypeInfo_var) == (il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 1));
		if (!L_0)
		{
			goto IL_0058;
		}
	}
	{
		RuntimeObject* L_1 = __this->____object;
		V_0 = ((String_t*)IsInstSealed((RuntimeObject*)L_1, String_t_il2cpp_TypeInfo_var));
		String_t* L_2 = V_0;
		if (L_2)
		{
			goto IL_003f;
		}
	}
	{
		ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC L_3;
		L_3 = ((  ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC (*) (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4*, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 2)))(__this, il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 2));
		V_1 = L_3;
		String_t* L_4;
		L_4 = ReadOnlySpan_1_ToString_m04AD05E39D10A41E67653C41A22108A810CA9857((&V_1), il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3));
		return L_4;
	}

IL_003f:
	{
		String_t* L_5 = V_0;
		int32_t L_6 = __this->____index;
		int32_t L_7 = __this->____length;
		NullCheck(L_5);
		String_t* L_8;
		L_8 = String_Substring_mB1D94F47935D22E130FF2C01DBB6A4135FBB76CE(L_5, L_6, ((int32_t)(L_7&((int32_t)2147483647LL))), NULL);
		return L_8;
	}

IL_0058:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_9 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 0)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_10;
		L_10 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_9, NULL);
		NullCheck(L_10);
		String_t* L_11;
		L_11 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_10);
		int32_t L_12 = __this->____length;
		int32_t L_13 = ((int32_t)(L_12&((int32_t)2147483647LL)));
		RuntimeObject* L_14 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_13);
		String_t* L_15;
		L_15 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral958BF5561D89C9A90653416FCB65BBE72DADDE1E, L_11, L_14, NULL);
		return L_15;
	}
}
IL2CPP_EXTERN_C  String_t* ReadOnlyMemory_1_ToString_m1AB8B8725FFC7144748E59C73875E2C6822E2321_AdjustorThunk (RuntimeObject* __this, const RuntimeMethod* method)
{
	ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* _thisAdjusted;
	_thisAdjusted = il2cpp_codegen_get_raw_data<ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4>(__this);
	String_t* _returnValue;
	_returnValue = ReadOnlyMemory_1_ToString_m1AB8B8725FFC7144748E59C73875E2C6822E2321(_thisAdjusted, method);
	return _returnValue;
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC ReadOnlyMemory_1_get_Span_m3BBCF2EFAFAB7DAA8882208AF319487E00DC3895_fshared (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	Span_1_tDEB40BEFA77B5E4BB49B058CD3050EEA4DD36C54 V_0;
	memset((&V_0), 0, sizeof(V_0));
	String_t* V_1 = NULL;
	ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC V_2;
	memset((&V_2), 0, sizeof(V_2));
	{
		int32_t L_0 = __this->____index;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_0039;
		}
	}
	{
		RuntimeObject* L_1 = __this->____object;
		NullCheck(((MemoryManager_1_tED55276A18D77758B15A7A09B9C0D4DB79480487*)CastclassClass((RuntimeObject*)L_1, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))));
		Span_1_tDEB40BEFA77B5E4BB49B058CD3050EEA4DD36C54 L_2;
		L_2 = VirtualFuncInvoker0< Span_1_tDEB40BEFA77B5E4BB49B058CD3050EEA4DD36C54 >::Invoke(4, ((MemoryManager_1_tED55276A18D77758B15A7A09B9C0D4DB79480487*)CastclassClass((RuntimeObject*)L_1, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 4))));
		V_0 = L_2;
		int32_t L_3 = __this->____index;
		int32_t L_4 = __this->____length;
		Span_1_tDEB40BEFA77B5E4BB49B058CD3050EEA4DD36C54 L_5;
		L_5 = ((  Span_1_tDEB40BEFA77B5E4BB49B058CD3050EEA4DD36C54 (*) (Span_1_tDEB40BEFA77B5E4BB49B058CD3050EEA4DD36C54*, int32_t, int32_t, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 5)))((&V_0), ((int32_t)(L_3&((int32_t)2147483647LL))), L_4, il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 5));
		ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC L_6;
		L_6 = ((  ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC (*) (Span_1_tDEB40BEFA77B5E4BB49B058CD3050EEA4DD36C54, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 6)))(L_5, NULL);
		return L_6;
	}

IL_0039:
	{
		bool L_7 = (Char_t521A6F19B456D956AF452D926C32709DC03D6B17_il2cpp_TypeInfo_var) == (il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 1));
		if (!L_7)
		{
			goto IL_008e;
		}
	}
	{
		RuntimeObject* L_8 = __this->____object;
		V_1 = ((String_t*)IsInstSealed((RuntimeObject*)L_8, String_t_il2cpp_TypeInfo_var));
		String_t* L_9 = V_1;
		if (!L_9)
		{
			goto IL_008e;
		}
	}
	{
		String_t* L_10 = V_1;
		NullCheck(L_10);
		Il2CppChar* L_11;
		L_11 = String_GetRawStringData_m87BC50B7B314C055E27A28032D1003D42FDE411D(L_10, NULL);
		Il2CppFullySharedGenericAny* L_12;
		L_12 = il2cpp_unsafe_as_ref<Il2CppFullySharedGenericAny>(L_11);
		String_t* L_13 = V_1;
		NullCheck(L_13);
		int32_t L_14;
		L_14 = String_get_Length_m42625D67623FA5CC7A44D47425CE86FB946542D2_inline(L_13, NULL);
		ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC L_15;
		memset((&L_15), 0, sizeof(L_15));
		ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_inline((&L_15), L_12, L_14, NULL);
		V_2 = L_15;
		int32_t L_16 = __this->____index;
		int32_t L_17 = __this->____length;
		ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC L_18;
		L_18 = ((  ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC (*) (ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC*, int32_t, int32_t, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8)))((&V_2), L_16, L_17, il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8));
		return L_18;
	}

IL_008e:
	{
		RuntimeObject* L_19 = __this->____object;
		if (!L_19)
		{
			goto IL_00b9;
		}
	}
	{
		RuntimeObject* L_20 = __this->____object;
		int32_t L_21 = __this->____index;
		int32_t L_22 = __this->____length;
		ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC L_23;
		memset((&L_23), 0, sizeof(L_23));
		ReadOnlySpan_1__ctor_mC9869776ABBFE9D2520512EEB39ABD1CFFE7F7B9_inline((&L_23), ((__Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC*)Castclass((RuntimeObject*)L_20, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 9))), L_21, ((int32_t)(L_22&((int32_t)2147483647LL))), il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 10));
		return L_23;
	}

IL_00b9:
	{
		il2cpp_codegen_initobj((&V_2), sizeof(ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC));
		ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC L_24 = V_2;
		return L_24;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyMemory_1_Equals_m2C16DF2AE78D8E7182CFAE8E3E07C3B20A777888_fshared (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4 V_0;
	memset((&V_0), 0, sizeof(V_0));
	Memory_1_t762D61B435521D1706EEDC25CA8C8EA1AE19AFEA V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		RuntimeObject* L_0 = ___0_obj;
		if (!((RuntimeObject*)IsInstSealed((RuntimeObject*)L_0, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 11))))
		{
			goto IL_0017;
		}
	}
	{
		RuntimeObject* L_1 = ___0_obj;
		V_0 = ((*(ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4*)UnBox(L_1, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 11))));
		ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4 L_2 = V_0;
		bool L_3;
		L_3 = ((  bool (*) (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4*, ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 12)))(__this, L_2, NULL);
		return L_3;
	}

IL_0017:
	{
		RuntimeObject* L_4 = ___0_obj;
		if (!((RuntimeObject*)IsInstSealed((RuntimeObject*)L_4, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 13))))
		{
			goto IL_0033;
		}
	}
	{
		RuntimeObject* L_5 = ___0_obj;
		V_1 = ((*(Memory_1_t762D61B435521D1706EEDC25CA8C8EA1AE19AFEA*)UnBox(L_5, il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 13))));
		Memory_1_t762D61B435521D1706EEDC25CA8C8EA1AE19AFEA L_6 = V_1;
		ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4 L_7;
		L_7 = ((  ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4 (*) (Memory_1_t762D61B435521D1706EEDC25CA8C8EA1AE19AFEA, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 14)))(L_6, NULL);
		bool L_8;
		L_8 = ((  bool (*) (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4*, ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 12)))(__this, L_7, NULL);
		return L_8;
	}

IL_0033:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C  bool ReadOnlyMemory_1_Equals_m2C16DF2AE78D8E7182CFAE8E3E07C3B20A777888_AdjustorThunk (RuntimeObject* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method)
{
	ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* _thisAdjusted;
	_thisAdjusted = il2cpp_codegen_get_raw_data<ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4>(__this);
	bool _returnValue;
	_returnValue = ReadOnlyMemory_1_Equals_m2C16DF2AE78D8E7182CFAE8E3E07C3B20A777888(_thisAdjusted, ___0_obj, method);
	return _returnValue;
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlyMemory_1_Equals_mF7DA75997B4FFDFB2D6F953E8DC580EC3C941A61_fshared (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4 ___0_other, const RuntimeMethod* method) 
{
	{
		RuntimeObject* L_0 = __this->____object;
		ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4 L_1 = ___0_other;
		RuntimeObject* L_2 = L_1.____object;
		if ((!(((RuntimeObject*)(RuntimeObject*)L_0) == ((RuntimeObject*)(RuntimeObject*)L_2))))
		{
			goto IL_002b;
		}
	}
	{
		int32_t L_3 = __this->____index;
		ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4 L_4 = ___0_other;
		int32_t L_5 = L_4.____index;
		if ((!(((uint32_t)L_3) == ((uint32_t)L_5))))
		{
			goto IL_002b;
		}
	}
	{
		int32_t L_6 = __this->____length;
		ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4 L_7 = ___0_other;
		int32_t L_8 = L_7.____length;
		return (bool)((((int32_t)L_6) == ((int32_t)L_8))? 1 : 0);
	}

IL_002b:
	{
		return (bool)0;
	}
}
IL2CPP_EXTERN_C  bool ReadOnlyMemory_1_Equals_mF7DA75997B4FFDFB2D6F953E8DC580EC3C941A61_AdjustorThunk (RuntimeObject* __this, ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4 ___0_other, const RuntimeMethod* method)
{
	ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* _thisAdjusted;
	_thisAdjusted = il2cpp_codegen_get_raw_data<ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4>(__this);
	bool _returnValue;
	_returnValue = ReadOnlyMemory_1_Equals_mF7DA75997B4FFDFB2D6F953E8DC580EC3C941A61(_thisAdjusted, ___0_other, method);
	return _returnValue;
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyMemory_1_GetHashCode_m96535F6C6512A16E6DBC2A8341F8FECDF2E47F54_fshared (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	{
		RuntimeObject* L_0 = __this->____object;
		if (L_0)
		{
			goto IL_000a;
		}
	}
	{
		return 0;
	}

IL_000a:
	{
		RuntimeObject* L_1 = __this->____object;
		NullCheck(L_1);
		int32_t L_2;
		L_2 = VirtualFuncInvoker0< int32_t >::Invoke(2, L_1);
		int32_t* L_3 = (int32_t*)(&__this->____index);
		int32_t L_4;
		L_4 = Int32_GetHashCode_m253D60FF7527A483E91004B7A2366F13E225E295(L_3, NULL);
		int32_t* L_5 = (int32_t*)(&__this->____length);
		int32_t L_6;
		L_6 = Int32_GetHashCode_m253D60FF7527A483E91004B7A2366F13E225E295(L_5, NULL);
		int32_t L_7;
		L_7 = ((  int32_t (*) (int32_t, int32_t, int32_t, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 15)))(L_2, L_4, L_6, il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 15));
		return L_7;
	}
}
IL2CPP_EXTERN_C  int32_t ReadOnlyMemory_1_GetHashCode_m96535F6C6512A16E6DBC2A8341F8FECDF2E47F54_AdjustorThunk (RuntimeObject* __this, const RuntimeMethod* method)
{
	ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* _thisAdjusted;
	_thisAdjusted = il2cpp_codegen_get_raw_data<ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4>(__this);
	int32_t _returnValue;
	_returnValue = ReadOnlyMemory_1_GetHashCode_m96535F6C6512A16E6DBC2A8341F8FECDF2E47F54(_thisAdjusted, method);
	return _returnValue;
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyMemory_1_CombineHashCodes_m74D5DE9AF0CCB1FF7B88058328C835DBD981C568_fshared (int32_t ___0_left, int32_t ___1_right, const RuntimeMethod* method) 
{
	{
		int32_t L_0 = ___0_left;
		int32_t L_1 = ___0_left;
		int32_t L_2 = ___1_right;
		return ((int32_t)(((int32_t)il2cpp_codegen_add(((int32_t)(L_0<<5)), L_1))^L_2));
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlyMemory_1_CombineHashCodes_m1F4667745BEC8579517F436310474B5FEE8379E6_fshared (int32_t ___0_h1, int32_t ___1_h2, int32_t ___2_h3, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	{
		int32_t L_0 = ___0_h1;
		int32_t L_1 = ___1_h2;
		int32_t L_2;
		L_2 = ((  int32_t (*) (int32_t, int32_t, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 16)))(L_0, L_1, NULL);
		int32_t L_3 = ___2_h3;
		int32_t L_4;
		L_4 = ((  int32_t (*) (int32_t, int32_t, const RuntimeMethod*))il2cpp_codegen_get_direct_method_pointer(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 16)))(L_2, L_3, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR RuntimeObject* ReadOnlyMemory_1_GetObjectStartLength_m76D2DB58E89EF8DAAB0BEEC5E80CC99E7C3CB752_fshared (ReadOnlyMemory_1_t192441E248CAB66088AAEDBD64DFEE110ADBEED4* __this, int32_t* ___0_start, int32_t* ___1_length, const RuntimeMethod* method) 
{
	{
		int32_t* L_0 = ___0_start;
		int32_t L_1 = __this->____index;
		*(L_0) = L_1;
		int32_t* L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		*(L_2) = L_3;
		RuntimeObject* L_4 = __this->____object;
		return L_4;
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlyNativeVector_1__ctor_m64EB14620E394C425562A5F9AD826C959C29BD96_fshared (ReadOnlyNativeVector_1_tE45C179B8DFEAD70E1F59D744D5C6999873C0FFC* __this, intptr_t ___0_ptr, int32_t ___1_size, const RuntimeMethod* method) 
{
	{
		intptr_t L_0 = ___0_ptr;
		__this->___m_Ptr = L_0;
		int32_t L_1 = ___1_size;
		__this->___m_Count = L_1;
		return;
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m570BAA2FA6B3B2F7F152D6619D1CF100D9349FAF (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000* __this, EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_12;
		L_12 = il2cpp_unsafe_as_ref<EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96>(L_11);
		int32_t L_13 = ___1_start;
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_14;
		L_14 = il2cpp_unsafe_add<EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96,int32_t>(L_12, L_13, sizeof(EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96));
		ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mF2ADB2B548C4E7719F88D0ABC14770AE5E4DE14E (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_2;
		L_2 = il2cpp_unsafe_as_ref<EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96>((uint8_t*)L_1);
		ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* ReadOnlySpan_1_get_Item_m6A5C732A45AE02479171B621A148DBC2399CC0E5 (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 L_2 = __this->____pointer;
		V_0 = L_2;
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_5;
		L_5 = il2cpp_unsafe_add<EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96,int32_t>(L_3, L_4, sizeof(EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_m7183D13AD806FDB2EC0884762F77A4C86FE4602A (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000* __this, Span_1_t2A675B8E3E38550E93916E5DCA96655003AAF435 ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mFAB3C81B4C721D97D620490285A98D10429F2C64_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t2A675B8E3E38550E93916E5DCA96655003AAF435 L_2 = ___0_destination;
		ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 L_3 = L_2.____pointer;
		V_0 = L_3;
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96, (Il2CppByReference*)(&V_0));
		ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 L_5 = __this->____pointer;
		V_0 = L_5;
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisEmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96_mE391F759232A81F0432F80E844CBA7DDB1004880(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_m033324D7B7BD7BAF8F65DE0934269BDDDB71EF5F (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000* __this, Span_1_t2A675B8E3E38550E93916E5DCA96655003AAF435 ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mFAB3C81B4C721D97D620490285A98D10429F2C64_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t2A675B8E3E38550E93916E5DCA96655003AAF435 L_2 = ___0_destination;
		ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 L_3 = L_2.____pointer;
		V_1 = L_3;
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96, (Il2CppByReference*)(&V_1));
		ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 L_5 = __this->____pointer;
		V_1 = L_5;
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisEmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96_mE391F759232A81F0432F80E844CBA7DDB1004880(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_mCA881F846F1762D5AE214F0AAA740E7CA119C7EC (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000 ReadOnlySpan_1_Slice_m7C47F3D3EA3870649051BCE9293B3938931EF55F (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 L_2 = __this->____pointer;
		V_0 = L_2;
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_5;
		L_5 = il2cpp_unsafe_add<EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96,int32_t>(L_3, L_4, sizeof(EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000 L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_m2310FC0E91B7ECFAE542316434BB4C9D6782042B_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000 ReadOnlySpan_1_Slice_m80AC0C5A0EBBFE2438C2D42F6048AC07AF86697D (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 L_5 = __this->____pointer;
		V_0 = L_5;
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_8;
		L_8 = il2cpp_unsafe_add<EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96,int32_t>(L_6, L_7, sizeof(EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000 L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_m2310FC0E91B7ECFAE542316434BB4C9D6782042B_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA* ReadOnlySpan_1_ToArray_m32FED539B1AE3E7D80E2C647267628D88C95851A (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA* L_1;
		L_1 = Array_Empty_TisEmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96_mD229BDA583D562BD2A433878A338C82536F745F3_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA* L_3 = (EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA*)(EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_6;
		L_6 = il2cpp_unsafe_as_ref<EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96>(L_5);
		ByReference_1_t96DAE667B9BC20DC5FA90542D560148F31E98B83 L_7 = __this->____pointer;
		V_0 = L_7;
		EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(EmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisEmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96_mE391F759232A81F0432F80E844CBA7DDB1004880(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_m410F5EE92CACE44CC4DE5DCC7D5D143EEA37EF03 (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000 ___0_left, ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000 ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000 L_0 = ___0_left;
		ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000 L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_mBDAC100928A2A40355010648140EA50C37DE399E(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_m65967C64A7A6961BD33CDE60AF90ABA8EFB3E9A0 (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_m3C18BC4937635B9FCA7A528656359E4BF954CA99 (ReadOnlySpan_1_t7F03D2582CD1D30379484DC4C7234A09661B8000* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m52859FE79EBD2B8DECF3E13A88DCA05F0BBEC0D5_gshared (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57* __this, HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_12;
		L_12 = il2cpp_unsafe_as_ref<HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5>(L_11);
		int32_t L_13 = ___1_start;
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_14;
		L_14 = il2cpp_unsafe_add<HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5,int32_t>(L_12, L_13, sizeof(HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5));
		ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m4F3AAB57F39E2E2579C12537324356199712C995_gshared (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	{
	}
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		ThrowHelper_ThrowInvalidTypeWithPointersNotSupported_m5707DE408588F6EAC3FC7D10F9520308CF8C8CCF(L_1, NULL);
	}

IL_0016:
	{
		int32_t L_2 = ___1_length;
		if ((((int32_t)L_2) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_3 = ___0_pointer;
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_4;
		L_4 = il2cpp_unsafe_as_ref<HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5>((uint8_t*)L_3);
		ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A L_5;
		memset((&L_5), 0, sizeof(L_5));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_5), L_4);
		__this->____pointer = L_5;
		int32_t L_6 = ___1_length;
		__this->____length = L_6;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* ReadOnlySpan_1_get_Item_m54C6853793A297EC8E291814DE88BEB8A7CE3E51_gshared (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A L_2 = __this->____pointer;
		V_0 = L_2;
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_5;
		L_5 = il2cpp_unsafe_add<HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5,int32_t>(L_3, L_4, sizeof(HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_mCC42376BE7A3B0B3FA269BB7B746C2A0E139C7CE_gshared (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57* __this, Span_1_t9281853CEBD9A6003A40E179A340A790E331B575 ___0_destination, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m70ECF63AA57B2B62F767D7B9290E6F6FD35B8E9E_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t9281853CEBD9A6003A40E179A340A790E331B575 L_2 = ___0_destination;
		ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A L_3 = L_2.____pointer;
		V_0 = L_3;
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5, (Il2CppByReference*)(&V_0));
		ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A L_5 = __this->____pointer;
		V_0 = L_5;
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisHashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5_mA8D04698C609F68E916C276ADC1E40C0EDB95A05(L_4, L_6, L_8, il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 5));
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_m1F29665F008B75D3A568BCBB9C2C5A85D085F7E2_gshared (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57* __this, Span_1_t9281853CEBD9A6003A40E179A340A790E331B575 ___0_destination, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	bool V_0 = false;
	ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m70ECF63AA57B2B62F767D7B9290E6F6FD35B8E9E_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t9281853CEBD9A6003A40E179A340A790E331B575 L_2 = ___0_destination;
		ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A L_3 = L_2.____pointer;
		V_1 = L_3;
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5, (Il2CppByReference*)(&V_1));
		ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A L_5 = __this->____pointer;
		V_1 = L_5;
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisHashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5_mA8D04698C609F68E916C276ADC1E40C0EDB95A05(L_4, L_6, L_8, il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 5));
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_m24869D7EE38C2A3AF6EB662716D082145E19E488_gshared (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		bool L_0 = (Char_t521A6F19B456D956AF452D926C32709DC03D6B17_il2cpp_TypeInfo_var) == (il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 1));
		if (!L_0)
		{
			goto IL_003e;
		}
	}
	{
		ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A L_1 = __this->____pointer;
		V_1 = L_1;
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_2;
		L_2 = IL2CPP_BY_REFERENCE_GET_VALUE(HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5, (Il2CppByReference*)(&V_1));
		Il2CppChar* L_3;
		L_3 = il2cpp_unsafe_as_ref<Il2CppChar>(L_2);
		V_0 = L_3;
		Il2CppChar* L_4 = V_0;
		uintptr_t L_5 = (il2cpp_codegen_conv<uintptr_t,Il2CppChar*,intptr_t,false,false>(L_4,NULL));
		int32_t L_6 = __this->____length;
		String_t* L_7;
		L_7 = String_CreateString_m3F8794FEB452558B8A68C65E1F0B603B3D94E0E2(NULL, (Il2CppChar*)L_5, 0, L_6, NULL);
		return L_7;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_8 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_9;
		L_9 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_8, NULL);
		NullCheck(L_9);
		String_t* L_10;
		L_10 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_9);
		int32_t L_11 = __this->____length;
		int32_t L_12 = L_11;
		RuntimeObject* L_13 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_12);
		String_t* L_14;
		L_14 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_10, L_13, NULL);
		return L_14;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57 ReadOnlySpan_1_Slice_mC99246C639C1C0F9BBF0C1F65B9A048B13049AA4_gshared (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A L_2 = __this->____pointer;
		V_0 = L_2;
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_5;
		L_5 = il2cpp_unsafe_add<HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5,int32_t>(L_3, L_4, sizeof(HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57 L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_m61A414D4F9636EAC0C3689FCCF1A7EA5ECD32F53_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57 ReadOnlySpan_1_Slice_m068A228D6A88F930B6917158C335F7964B9B16ED_gshared (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A L_5 = __this->____pointer;
		V_0 = L_5;
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_8;
		L_8 = il2cpp_unsafe_add<HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5,int32_t>(L_6, L_7, sizeof(HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57 L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_m61A414D4F9636EAC0C3689FCCF1A7EA5ECD32F53_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* ReadOnlySpan_1_ToArray_m3EAFADE1D32F93E52A5C68335CEEBDB840D7580A_gshared (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* L_1;
		L_1 = Array_Empty_TisHashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5_m7546ECBE8AAEBE56E0F447E66B1A47851A568FCC_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* L_3 = (HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5*)(HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_6;
		L_6 = il2cpp_unsafe_as_ref<HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5>(L_5);
		ByReference_1_t5E82C4E8BBB02F58925FEA3903F0DCB90D59054A L_7 = __this->____pointer;
		V_0 = L_7;
		HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(HashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisHashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5_mA8D04698C609F68E916C276ADC1E40C0EDB95A05(L_6, L_8, L_10, il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 5));
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_m7F618D95C6871AD1E1E7CB4BFF6DA57AF103E484_gshared (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57 ___0_left, ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57 ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57 L_0 = ___0_left;
		ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57 L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_m3E5BDB77835A736157FA2EC596A124328094905D(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_m0BA22FF13C56D3EE51C779C23D705DC5FFD10783_gshared (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_m4E42154AB110E3CF06C3A6D6E839B10EC4758644_gshared (ReadOnlySpan_1_tE0300BBDB651E6D564DFE7BDA80CDBF9E4ABFF57* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m608B0D10A71E6646CFC375049BEE1BD4A91E42D8 (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA* __this, NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_12;
		L_12 = il2cpp_unsafe_as_ref<NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62>(L_11);
		int32_t L_13 = ___1_start;
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_14;
		L_14 = il2cpp_unsafe_add<NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62,int32_t>(L_12, L_13, sizeof(NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62));
		ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mA00771A913574E450B7709FFE23409830DB02E45 (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_2;
		L_2 = il2cpp_unsafe_as_ref<NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62>((uint8_t*)L_1);
		ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* ReadOnlySpan_1_get_Item_m700CC33B3C856FED3CCC86C3ED00E982364740EE (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 L_2 = __this->____pointer;
		V_0 = L_2;
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_5;
		L_5 = il2cpp_unsafe_add<NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62,int32_t>(L_3, L_4, sizeof(NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_m95C90CC8DDDFB4AF85F92507CEC7AE3E1CB452C2 (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA* __this, Span_1_t84CC3492C4F25DC684EB1A4E00493E60CD98D428 ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mCBA967D766B41C6F7A5A958282339CC12C808833_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t84CC3492C4F25DC684EB1A4E00493E60CD98D428 L_2 = ___0_destination;
		ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 L_3 = L_2.____pointer;
		V_0 = L_3;
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62, (Il2CppByReference*)(&V_0));
		ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 L_5 = __this->____pointer;
		V_0 = L_5;
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisNativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62_m6931525DB5EBBF296FB06571C6E6FBD595137197(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_mC5E1BDB5173850E33F2CFD3639E9121CE51BC2DD (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA* __this, Span_1_t84CC3492C4F25DC684EB1A4E00493E60CD98D428 ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mCBA967D766B41C6F7A5A958282339CC12C808833_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t84CC3492C4F25DC684EB1A4E00493E60CD98D428 L_2 = ___0_destination;
		ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 L_3 = L_2.____pointer;
		V_1 = L_3;
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62, (Il2CppByReference*)(&V_1));
		ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 L_5 = __this->____pointer;
		V_1 = L_5;
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisNativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62_m6931525DB5EBBF296FB06571C6E6FBD595137197(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_mA3FD0ADDF9145E4C17E97DAF1747D1C5FB02CD88 (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA ReadOnlySpan_1_Slice_mCC37A7202F48A6418256606101B999C623E89A32 (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 L_2 = __this->____pointer;
		V_0 = L_2;
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_5;
		L_5 = il2cpp_unsafe_add<NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62,int32_t>(L_3, L_4, sizeof(NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_mB77B497E05DB783A900DCEAD111F61A3F27C7D35_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA ReadOnlySpan_1_Slice_m51C8F4D23DD6380A637AEED12D9D6FBB9D661934 (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 L_5 = __this->____pointer;
		V_0 = L_5;
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_8;
		L_8 = il2cpp_unsafe_add<NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62,int32_t>(L_6, L_7, sizeof(NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_mB77B497E05DB783A900DCEAD111F61A3F27C7D35_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0* ReadOnlySpan_1_ToArray_m7B7801DA2AD817458514F0E76FB154378963B3D1 (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0* L_1;
		L_1 = Array_Empty_TisNativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62_mBDB8DDE2D2948EDF2432FC77141B7D1360CDA732_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0* L_3 = (NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0*)(NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_6;
		L_6 = il2cpp_unsafe_as_ref<NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62>(L_5);
		ByReference_1_tCE52B202D24A2ECB85FE96F1DA3C0C6BB73E4001 L_7 = __this->____pointer;
		V_0 = L_7;
		NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(NativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisNativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62_m6931525DB5EBBF296FB06571C6E6FBD595137197(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_m56807FF5E068AE9B6D327B3F1D0797B54D179E23 (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA ___0_left, ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA L_0 = ___0_left;
		ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_m1C315B0091ADD10B08153159755014876AB3A48B(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_mD43FB77B142634D2E86E0FE099E74A56DB9C9020 (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_m65BE3303AD5CA8A8C18952615D5A45C5B270B3C7 (ReadOnlySpan_1_tE3210CB260ACE9EAED2369F5CCC0DB30753D60FA* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m0C325927D022A4794D0573B41E1BAC18B83DB914 (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84* __this, SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_12;
		L_12 = il2cpp_unsafe_as_ref<SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474>(L_11);
		int32_t L_13 = ___1_start;
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_14;
		L_14 = il2cpp_unsafe_add<SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474,int32_t>(L_12, L_13, sizeof(SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474));
		ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mAAA13269ECF8F777B3D66AA1381ABAF562ECAFAD (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_2;
		L_2 = il2cpp_unsafe_as_ref<SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474>((uint8_t*)L_1);
		ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* ReadOnlySpan_1_get_Item_m2D69BC4DF6C72A65AF6044FD5D9A1DA836E581CC (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F L_2 = __this->____pointer;
		V_0 = L_2;
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_5;
		L_5 = il2cpp_unsafe_add<SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474,int32_t>(L_3, L_4, sizeof(SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_mC13BF984D3064FAB75E9F31240A0D461090D28B5 (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84* __this, Span_1_t291EAC5144D1F469ED3426F74052EFC6F1E9BCB8 ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mBA6FA6140EADE76BD14920BDC6A3E87EDB72FB76_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t291EAC5144D1F469ED3426F74052EFC6F1E9BCB8 L_2 = ___0_destination;
		ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F L_3 = L_2.____pointer;
		V_0 = L_3;
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474, (Il2CppByReference*)(&V_0));
		ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F L_5 = __this->____pointer;
		V_0 = L_5;
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisSelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474_m8B225EBD79F98163072E7428252E4FDAFE5A3E1A(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_m69C0DC7A9642D41BA974889DBF468384BE169D08 (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84* __this, Span_1_t291EAC5144D1F469ED3426F74052EFC6F1E9BCB8 ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mBA6FA6140EADE76BD14920BDC6A3E87EDB72FB76_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t291EAC5144D1F469ED3426F74052EFC6F1E9BCB8 L_2 = ___0_destination;
		ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F L_3 = L_2.____pointer;
		V_1 = L_3;
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474, (Il2CppByReference*)(&V_1));
		ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F L_5 = __this->____pointer;
		V_1 = L_5;
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisSelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474_m8B225EBD79F98163072E7428252E4FDAFE5A3E1A(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_mFD9D2B3920E4AFC4709C68A4404CD723A0ED8A19 (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84 ReadOnlySpan_1_Slice_m76C587257127EDB2661E9B2E077F2D6C2904394C (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F L_2 = __this->____pointer;
		V_0 = L_2;
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_5;
		L_5 = il2cpp_unsafe_add<SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474,int32_t>(L_3, L_4, sizeof(SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84 L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_m68B11A5CBD341B71C3B49A184D9A4A0F68B2BC1B_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84 ReadOnlySpan_1_Slice_m31FCCE32E3D3F2C5C6059960D7F47D3C0D63FAB6 (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F L_5 = __this->____pointer;
		V_0 = L_5;
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_8;
		L_8 = il2cpp_unsafe_add<SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474,int32_t>(L_6, L_7, sizeof(SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84 L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_m68B11A5CBD341B71C3B49A184D9A4A0F68B2BC1B_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06* ReadOnlySpan_1_ToArray_m935765D78782E0DA24C534996DA3AF27448E26F6 (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06* L_1;
		L_1 = Array_Empty_TisSelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474_m4433599FD227186796BAB47DC5BED2AF106ED67E_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06* L_3 = (SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06*)(SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_6;
		L_6 = il2cpp_unsafe_as_ref<SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474>(L_5);
		ByReference_1_t30C53FE69558F45E4B0A33666EDEDF4CF1F8630F L_7 = __this->____pointer;
		V_0 = L_7;
		SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(SelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisSelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474_m8B225EBD79F98163072E7428252E4FDAFE5A3E1A(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_mD43349D875DC6D0FB0535BE3B3830C1450435420 (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84 ___0_left, ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84 ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84 L_0 = ___0_left;
		ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84 L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_m273AE2A699A7739E89673154DA9E3BE6B08A180D(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_m721EBEC6C55EAE29C1D18E357CBE1B795B121355 (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_m5003E9917221426C5BF4F1DD6CCD9F9C627F8CB2 (ReadOnlySpan_1_t274763BD5FC8FCD51E9C71396D664D8858CF9E84* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m5E675F5E8D162043F87E2E91F1A8D105D7D6C805 (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724* __this, UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_12;
		L_12 = il2cpp_unsafe_as_ref<UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD>(L_11);
		int32_t L_13 = ___1_start;
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_14;
		L_14 = il2cpp_unsafe_add<UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD,int32_t>(L_12, L_13, sizeof(UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD));
		ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mE81A67141DF0778695C0ED7D4B8CD743D3D9937A (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_2;
		L_2 = il2cpp_unsafe_as_ref<UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD>((uint8_t*)L_1);
		ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* ReadOnlySpan_1_get_Item_m5AD40C70CAAA66F55544EAC5853562624CEDD4EE (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD,int32_t>(L_3, L_4, sizeof(UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_m462FF7C791121DD80E6F704DB2D83D2C2ACFC393 (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724* __this, Span_1_t9ED8A526081AA124D11AF2D755A0B15118AE965A ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mAE734F1E7D866942E70763D9232D006153CC93C8_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t9ED8A526081AA124D11AF2D755A0B15118AE965A L_2 = ___0_destination;
		ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F L_3 = L_2.____pointer;
		V_0 = L_3;
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD, (Il2CppByReference*)(&V_0));
		ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD_mC690AEF1F47ED7A260D15E587C4C342E207B8C32(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_mEF58D18A89697D8ABD7CBF3429385673C7761681 (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724* __this, Span_1_t9ED8A526081AA124D11AF2D755A0B15118AE965A ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mAE734F1E7D866942E70763D9232D006153CC93C8_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t9ED8A526081AA124D11AF2D755A0B15118AE965A L_2 = ___0_destination;
		ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F L_3 = L_2.____pointer;
		V_1 = L_3;
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD, (Il2CppByReference*)(&V_1));
		ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F L_5 = __this->____pointer;
		V_1 = L_5;
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD_mC690AEF1F47ED7A260D15E587C4C342E207B8C32(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_m0A37625A3D8AD5F461CF2313B575BFA3733E2101 (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724 ReadOnlySpan_1_Slice_m1A17102D00964F8C9CAA5228E1BDEE0B6E117306 (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD,int32_t>(L_3, L_4, sizeof(UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724 L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_mE74E20E42241965E7A458DF5E23A7FA9058C4F4E_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724 ReadOnlySpan_1_Slice_m686B172296E5F07DD0F950F9CC4BEAACA8803F5E (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_8;
		L_8 = il2cpp_unsafe_add<UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD,int32_t>(L_6, L_7, sizeof(UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724 L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_mE74E20E42241965E7A458DF5E23A7FA9058C4F4E_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C* ReadOnlySpan_1_ToArray_m4DAE4DF83F97F2C213CF0F4123E98C8EC177E78D (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C* L_1;
		L_1 = Array_Empty_TisUnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD_m14FA981EC22CA08E194019E3506AD1ABB6322E6D_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C* L_3 = (UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C*)(UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_6;
		L_6 = il2cpp_unsafe_as_ref<UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD>(L_5);
		ByReference_1_t61031BD4E188D1EF121FD50BDD708DCE448F2C4F L_7 = __this->____pointer;
		V_0 = L_7;
		UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisUnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD_mC690AEF1F47ED7A260D15E587C4C342E207B8C32(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_m76CC706E0DC452534C66712C378BE8BC1C6FB5EB (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724 ___0_left, ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724 ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724 L_0 = ___0_left;
		ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724 L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_mF3F15A8AA6E17FA6D014FF4ABE0086AD06B6D198(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_m76978FAF00A8E3252E8313F55DFC9F929D49DFAC (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_m43C6A9CCE77A1684A388D45472B151BC1E9E2FB5 (ReadOnlySpan_1_tE2870E9FEF162F87E01410AAAD6F1D8D2CF73724* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m2F11BBDD5F40B3226343C8301D11CC6E963E6AA6 (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085* __this, UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_12;
		L_12 = il2cpp_unsafe_as_ref<UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D>(L_11);
		int32_t L_13 = ___1_start;
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_14;
		L_14 = il2cpp_unsafe_add<UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D,int32_t>(L_12, L_13, sizeof(UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D));
		ByReference_1_tC71D682DBC538763066DF671429413D25394012A L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m6D5420C8A93291544AE831713247C1704DF9BD52 (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_2;
		L_2 = il2cpp_unsafe_as_ref<UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D>((uint8_t*)L_1);
		ByReference_1_tC71D682DBC538763066DF671429413D25394012A L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* ReadOnlySpan_1_get_Item_m98B57C2A5E139669314D54C37555841CBDE6B522 (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_tC71D682DBC538763066DF671429413D25394012A V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_tC71D682DBC538763066DF671429413D25394012A L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_mACF46BD6440A3D12A9E678D67489845FB950A350 (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085* __this, Span_1_t9361F6740620C10133091ACD2A48E3B994B1D176 ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_tC71D682DBC538763066DF671429413D25394012A V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m757FB90F888A97214E70C7D7DB66DCBB57ED9317_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t9361F6740620C10133091ACD2A48E3B994B1D176 L_2 = ___0_destination;
		ByReference_1_tC71D682DBC538763066DF671429413D25394012A L_3 = L_2.____pointer;
		V_0 = L_3;
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D, (Il2CppByReference*)(&V_0));
		ByReference_1_tC71D682DBC538763066DF671429413D25394012A L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D_m5753FD640BD432A226561D50E1F14CBEEFFFB9B2(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_mD02B4DAC081D1126CCAFF03C10856E9499F4FD75 (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085* __this, Span_1_t9361F6740620C10133091ACD2A48E3B994B1D176 ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_tC71D682DBC538763066DF671429413D25394012A V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m757FB90F888A97214E70C7D7DB66DCBB57ED9317_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t9361F6740620C10133091ACD2A48E3B994B1D176 L_2 = ___0_destination;
		ByReference_1_tC71D682DBC538763066DF671429413D25394012A L_3 = L_2.____pointer;
		V_1 = L_3;
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D, (Il2CppByReference*)(&V_1));
		ByReference_1_tC71D682DBC538763066DF671429413D25394012A L_5 = __this->____pointer;
		V_1 = L_5;
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D_m5753FD640BD432A226561D50E1F14CBEEFFFB9B2(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_mF1043B2E0ED0B5BDDE0B51B193FACBE22DDA8DD9 (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_tC71D682DBC538763066DF671429413D25394012A V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085 ReadOnlySpan_1_Slice_m21882D8D2EB4B8F82D2C107BE2C24206DB7F4009 (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_tC71D682DBC538763066DF671429413D25394012A V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_tC71D682DBC538763066DF671429413D25394012A L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085 L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_mE51F6529B403BD5E3C8AAE7BAE04BC3F93F7C31F_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085 ReadOnlySpan_1_Slice_m3871F3E7E821A4EC6AF2A9C5A1D4596CAFB68983 (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_tC71D682DBC538763066DF671429413D25394012A V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_tC71D682DBC538763066DF671429413D25394012A L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_8;
		L_8 = il2cpp_unsafe_add<UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D,int32_t>(L_6, L_7, sizeof(UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085 L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_mE51F6529B403BD5E3C8AAE7BAE04BC3F93F7C31F_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A* ReadOnlySpan_1_ToArray_m6E1A66F46B330789396D8C37C0E94F05B67372A9 (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_tC71D682DBC538763066DF671429413D25394012A V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A* L_1;
		L_1 = Array_Empty_TisUnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D_mB80BD27875E5AD9B06C08FC9D673F81494E06C0D_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A* L_3 = (UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A*)(UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_6;
		L_6 = il2cpp_unsafe_as_ref<UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D>(L_5);
		ByReference_1_tC71D682DBC538763066DF671429413D25394012A L_7 = __this->____pointer;
		V_0 = L_7;
		UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisUnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D_m5753FD640BD432A226561D50E1F14CBEEFFFB9B2(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_m1438CC85E8FE3070B8950EC1DF36DD564AB671C7 (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085 ___0_left, ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085 ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085 L_0 = ___0_left;
		ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085 L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_mAA0D16E0236C8BED9AB454299585D774E815A4A8(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_m3660C302C942FD77049B0CAD4AC68EB137DDA8A5 (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_m727A5786C807A6259D66FE3A64E0D1F5B3B593AA (ReadOnlySpan_1_t45680D5970EE2CDABC05A4D1502128ECAEB17085* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mAA7A1052208657A7111E40B70FDCA2A68B1A0947 (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7* __this, UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_12;
		L_12 = il2cpp_unsafe_as_ref<UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692>(L_11);
		int32_t L_13 = ___1_start;
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_14;
		L_14 = il2cpp_unsafe_add<UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692,int32_t>(L_12, L_13, sizeof(UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692));
		ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m33DDE487056A39B3BC9C2E571A2CEA7E13D55B1E (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_2;
		L_2 = il2cpp_unsafe_as_ref<UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692>((uint8_t*)L_1);
		ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* ReadOnlySpan_1_get_Item_m8ED7F37A0082EDBAB853E9946CBA1F644CEC31AF (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_m0D2DD6C54E7953D98BE0C9063E11CE5F6E204AE6 (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7* __this, Span_1_t093DFA1FE4BCEB341D9AFE57AD01A8FEBF32B4AB ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m9A18653FCB90AB3ACEBA696165B559FB2BC04AD7_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t093DFA1FE4BCEB341D9AFE57AD01A8FEBF32B4AB L_2 = ___0_destination;
		ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D L_3 = L_2.____pointer;
		V_0 = L_3;
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692, (Il2CppByReference*)(&V_0));
		ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692_mC45CF9E0F2492C756D55FAAD0F34035EAC00922D(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_m6EEA709B6D29E6703041EAF8412D7BAFE54D9D60 (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7* __this, Span_1_t093DFA1FE4BCEB341D9AFE57AD01A8FEBF32B4AB ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m9A18653FCB90AB3ACEBA696165B559FB2BC04AD7_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t093DFA1FE4BCEB341D9AFE57AD01A8FEBF32B4AB L_2 = ___0_destination;
		ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D L_3 = L_2.____pointer;
		V_1 = L_3;
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692, (Il2CppByReference*)(&V_1));
		ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D L_5 = __this->____pointer;
		V_1 = L_5;
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692_mC45CF9E0F2492C756D55FAAD0F34035EAC00922D(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_mAAA5018256445B0A1B95AA7213E518CEFD28FA52 (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7 ReadOnlySpan_1_Slice_m508AAB58F2C24C123188E44363B6E7BD9CCF61B7 (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7 L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_m199E5AF4F96498C11635398C59864ECAB82E7455_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7 ReadOnlySpan_1_Slice_mEDFF49D53D3CD81EAF4E97B62985909F2B1CC9FD (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_8;
		L_8 = il2cpp_unsafe_add<UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692,int32_t>(L_6, L_7, sizeof(UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7 L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_m199E5AF4F96498C11635398C59864ECAB82E7455_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B* ReadOnlySpan_1_ToArray_m708CF60D3276EC800AC6035D5CBAE8C7F449968B (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B* L_1;
		L_1 = Array_Empty_TisUnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692_m8225D086EDE4F1EA4A744724F13D762BD6A7FFA2_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B* L_3 = (UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B*)(UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_6;
		L_6 = il2cpp_unsafe_as_ref<UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692>(L_5);
		ByReference_1_t354B4A95283A59F41EFFFE068C7BCCDD5B4DF69D L_7 = __this->____pointer;
		V_0 = L_7;
		UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisUnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692_mC45CF9E0F2492C756D55FAAD0F34035EAC00922D(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_m8CA3ACF501717BD5F9131EABF09D05D540CAE146 (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7 ___0_left, ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7 ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7 L_0 = ___0_left;
		ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7 L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_mBCAD4291296A130D084599C071B39A72441A6041(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_m75BDD2461A1FFD7278388A31C55D84A5B604D5A1 (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_m92CDF0BFB26B1ECFBC53061EC8FE3DACE549987C (ReadOnlySpan_1_t5958E85C901E89A8E7C5DBF11DE12814057072B7* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mE418BAFE8F76B4E12877C45D607567B3F59BFBC8 (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E* __this, UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_12;
		L_12 = il2cpp_unsafe_as_ref<UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B>(L_11);
		int32_t L_13 = ___1_start;
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_14;
		L_14 = il2cpp_unsafe_add<UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B,int32_t>(L_12, L_13, sizeof(UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B));
		ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mCA18A92CD10111753DACA7E015842930111D8CB2 (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_2;
		L_2 = il2cpp_unsafe_as_ref<UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B>((uint8_t*)L_1);
		ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* ReadOnlySpan_1_get_Item_m532749192F7E0DCDAD1DDA8415C52D1B25BF5AA3 (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_mD224A407D0BB9254768A5B562AF61FD5F4C72B60 (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E* __this, Span_1_tCF93B7CB319A45CD677BBDFD2A55AD47DF463EB3 ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m64759923EC787AC67D237C126B1F9912A0757B25_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_tCF93B7CB319A45CD677BBDFD2A55AD47DF463EB3 L_2 = ___0_destination;
		ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD L_3 = L_2.____pointer;
		V_0 = L_3;
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B, (Il2CppByReference*)(&V_0));
		ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B_mEE1B8052EF8A53F69256C0CA82FEBB3DBA8851BD(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_m422F9A851A2C1A4FF5E6A81A46F4A64D27A5AB64 (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E* __this, Span_1_tCF93B7CB319A45CD677BBDFD2A55AD47DF463EB3 ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m64759923EC787AC67D237C126B1F9912A0757B25_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_tCF93B7CB319A45CD677BBDFD2A55AD47DF463EB3 L_2 = ___0_destination;
		ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD L_3 = L_2.____pointer;
		V_1 = L_3;
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B, (Il2CppByReference*)(&V_1));
		ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD L_5 = __this->____pointer;
		V_1 = L_5;
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B_mEE1B8052EF8A53F69256C0CA82FEBB3DBA8851BD(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_mD029C64D210A944CE10F606D7746BFE758BE1E83 (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E ReadOnlySpan_1_Slice_m0EFC5D7F3C3C50BC9BC997C24FA7E0225C77E4B5 (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_m3F71A8FCBA59B8D461F3B6CA8F89B020499102F8_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E ReadOnlySpan_1_Slice_mDE1C92A75905CE447C0E91872495892163285242 (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_8;
		L_8 = il2cpp_unsafe_add<UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B,int32_t>(L_6, L_7, sizeof(UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_m3F71A8FCBA59B8D461F3B6CA8F89B020499102F8_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC* ReadOnlySpan_1_ToArray_m68FF07494DFCC75CA7B9A37374E671C3E8778FF7 (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC* L_1;
		L_1 = Array_Empty_TisUnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B_mD5A5585240A77F26BE14BF51B1F8B7C2259B0019_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC* L_3 = (UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC*)(UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_6;
		L_6 = il2cpp_unsafe_as_ref<UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B>(L_5);
		ByReference_1_tE3DF7EC34FB0E036412F02E5F8E99484861BAEAD L_7 = __this->____pointer;
		V_0 = L_7;
		UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisUnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B_mEE1B8052EF8A53F69256C0CA82FEBB3DBA8851BD(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_mD9C6F9460372638CF531AC5345C89547E37694A7 (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E ___0_left, ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E L_0 = ___0_left;
		ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_mE6044990D7E1998FCBA25CBD93EC07FB978178A3(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_m1561401F7190CD7EA7E7BCA79EB608779FC3EEAC (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_m8B91F1E659BB530A8A4BBFBA9599BD143BDA6DD2 (ReadOnlySpan_1_t2C9F593EF5E4AD148EC8401C095671A8B5B33A7E* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mEB5134B131D0E170994F7494CF7B926025DB115D (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974* __this, UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_12;
		L_12 = il2cpp_unsafe_as_ref<UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0>(L_11);
		int32_t L_13 = ___1_start;
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_14;
		L_14 = il2cpp_unsafe_add<UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0,int32_t>(L_12, L_13, sizeof(UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0));
		ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mD410A300E402FE08E89132BFAB0DCF881D3A4578 (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_2;
		L_2 = il2cpp_unsafe_as_ref<UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0>((uint8_t*)L_1);
		ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* ReadOnlySpan_1_get_Item_m161FDA2AF27E9551881AF5113CC0DB16CD228A22 (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_m4481713E73C1C2D87CA4427A52238E9FFE94C3EB (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974* __this, Span_1_t140ED24BBE87C7CE97312D06D5316A9801E31506 ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m25AA5DB60DDFA74CDC6FC67BCE440F807F40C824_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t140ED24BBE87C7CE97312D06D5316A9801E31506 L_2 = ___0_destination;
		ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 L_3 = L_2.____pointer;
		V_0 = L_3;
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0, (Il2CppByReference*)(&V_0));
		ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0_mF923EFF1994ED30D7E774A6A60C3E27D9A9CFEB0(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_m482AAA43086A659D3B44458010B23AFAA06FAE72 (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974* __this, Span_1_t140ED24BBE87C7CE97312D06D5316A9801E31506 ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m25AA5DB60DDFA74CDC6FC67BCE440F807F40C824_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t140ED24BBE87C7CE97312D06D5316A9801E31506 L_2 = ___0_destination;
		ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 L_3 = L_2.____pointer;
		V_1 = L_3;
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0, (Il2CppByReference*)(&V_1));
		ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 L_5 = __this->____pointer;
		V_1 = L_5;
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0_mF923EFF1994ED30D7E774A6A60C3E27D9A9CFEB0(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_m364E1785B96B2251A8440C3BAC04C660E3479CEB (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974 ReadOnlySpan_1_Slice_mA6CFAB3B79A8C4796C3ABE6658206A3C22936085 (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974 L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_m0A622A67EF6097E611538708F12B2AFCDBD113A1_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974 ReadOnlySpan_1_Slice_m33DD63C018A322555D2CBBBE10758907E6371125 (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_8;
		L_8 = il2cpp_unsafe_add<UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0,int32_t>(L_6, L_7, sizeof(UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974 L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_m0A622A67EF6097E611538708F12B2AFCDBD113A1_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1* ReadOnlySpan_1_ToArray_mECE62226B3A5EE00DED45C53014CFDF63E149BAE (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1* L_1;
		L_1 = Array_Empty_TisUnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0_m81189A63B159A0BC9CF1D06BCB85661915D86FEB_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1* L_3 = (UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1*)(UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_6;
		L_6 = il2cpp_unsafe_as_ref<UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0>(L_5);
		ByReference_1_t5D507A8BE26BC84756E30163201D25135DFB82A3 L_7 = __this->____pointer;
		V_0 = L_7;
		UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisUnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0_mF923EFF1994ED30D7E774A6A60C3E27D9A9CFEB0(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_mFF252618100520D5459BBB026D18309BA70258C2 (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974 ___0_left, ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974 ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974 L_0 = ___0_left;
		ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974 L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_mE014CA0F1BF433B90328F47079B9D6A39F491376(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_m0D0DEA968CE25B4D93F60AE55FAF300165A6F3B6 (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_mB312A1CB4929D78F97971315202646EEC20F2C8D (ReadOnlySpan_1_tC069AED9CE39F0F4AF434A60781FDC641490E974* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m57B50A119CB5C15D895BE4D8AE7AD0EC3DB2AE1C (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44* __this, UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_12;
		L_12 = il2cpp_unsafe_as_ref<UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718>(L_11);
		int32_t L_13 = ___1_start;
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_14;
		L_14 = il2cpp_unsafe_add<UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718,int32_t>(L_12, L_13, sizeof(UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718));
		ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mFA20344976D826FC2C274A834141568E60CF1C41 (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_2;
		L_2 = il2cpp_unsafe_as_ref<UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718>((uint8_t*)L_1);
		ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* ReadOnlySpan_1_get_Item_m9FA1BC0E559A238DB85D6C394431613EF6D1C912 (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_m36269F94D96E64B8C76A76A5A81F98732BDAA1ED (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44* __this, Span_1_tF176F22E2BDE5E54D571766DE8FE21ACFF6CE298 ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mFD0E4725CBEC468524ED6C42354367A9A7359B95_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_tF176F22E2BDE5E54D571766DE8FE21ACFF6CE298 L_2 = ___0_destination;
		ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E L_3 = L_2.____pointer;
		V_0 = L_3;
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718, (Il2CppByReference*)(&V_0));
		ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718_m31B03CF22D0E106887FFB49A9FD2BEC54BEB659C(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_m6B3E3BC9772DF6300E69BC1D29668E5D7E9F2DFE (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44* __this, Span_1_tF176F22E2BDE5E54D571766DE8FE21ACFF6CE298 ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mFD0E4725CBEC468524ED6C42354367A9A7359B95_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_tF176F22E2BDE5E54D571766DE8FE21ACFF6CE298 L_2 = ___0_destination;
		ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E L_3 = L_2.____pointer;
		V_1 = L_3;
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718, (Il2CppByReference*)(&V_1));
		ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E L_5 = __this->____pointer;
		V_1 = L_5;
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718_m31B03CF22D0E106887FFB49A9FD2BEC54BEB659C(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_m25F6F75A5F83A7718391D78ABAA79AC113834BA8 (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44 ReadOnlySpan_1_Slice_m281B5F126175A24079897CAE694CBEB012476B75 (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44 L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_mA8962BCDAF15875BAA1631B9B69E1AC9230C568A_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44 ReadOnlySpan_1_Slice_m5B38060FD3E682A7F9E63884F09373040AA01C2F (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_8;
		L_8 = il2cpp_unsafe_add<UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718,int32_t>(L_6, L_7, sizeof(UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44 L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_mA8962BCDAF15875BAA1631B9B69E1AC9230C568A_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3* ReadOnlySpan_1_ToArray_m96B6D7BB4635BCDCAC0664D9DEEB80B666275D65 (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3* L_1;
		L_1 = Array_Empty_TisUnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718_m6DEB24EE574A3109DB94AA1CFC7A5BA936F84D38_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3* L_3 = (UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3*)(UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_6;
		L_6 = il2cpp_unsafe_as_ref<UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718>(L_5);
		ByReference_1_tD80D8F3A4406679DD5CCC1ABA479A308514D393E L_7 = __this->____pointer;
		V_0 = L_7;
		UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisUnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718_m31B03CF22D0E106887FFB49A9FD2BEC54BEB659C(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_mCF84881D054EAB14DC95F42E72F8B77B1AAF79FE (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44 ___0_left, ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44 ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44 L_0 = ___0_left;
		ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44 L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_m876FCAB5A193A17183A4C1055D7D78BF713D1E18(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_mD9D8965F7459C54F3B5D270C08D9045FCE5D3A9F (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_m0441F743AE7A7D6E633E6914C58A5833448BE5A0 (ReadOnlySpan_1_t37390238ECF9A0EFF4CB76B7DBB7D843AC6EED44* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m3CE2144C56D797A26A410A0E721647C49F1C7911 (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71* __this, UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_12;
		L_12 = il2cpp_unsafe_as_ref<UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF>(L_11);
		int32_t L_13 = ___1_start;
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_14;
		L_14 = il2cpp_unsafe_add<UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF,int32_t>(L_12, L_13, sizeof(UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF));
		ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m729EEF0D26B094E266E97D2363E9AE019C5111C2 (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_2;
		L_2 = il2cpp_unsafe_as_ref<UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF>((uint8_t*)L_1);
		ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* ReadOnlySpan_1_get_Item_mB6E7B868E780FD750B8D126D693BC21D70891C59 (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_m4D629049AA36AECB1CC99ED29CA62B07DD71A479 (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71* __this, Span_1_t5AD383DD652E3E6DB3205BDF87EE6BD77466A034 ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m796AE228F2062910CC25672EFEBF8E6F196B79BB_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t5AD383DD652E3E6DB3205BDF87EE6BD77466A034 L_2 = ___0_destination;
		ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA L_3 = L_2.____pointer;
		V_0 = L_3;
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF, (Il2CppByReference*)(&V_0));
		ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF_m531E222DA3CEAB4F838160BE8BF0D076B903940C(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_m081261D096219E736EB4704994639CA61A9A15F3 (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71* __this, Span_1_t5AD383DD652E3E6DB3205BDF87EE6BD77466A034 ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m796AE228F2062910CC25672EFEBF8E6F196B79BB_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t5AD383DD652E3E6DB3205BDF87EE6BD77466A034 L_2 = ___0_destination;
		ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA L_3 = L_2.____pointer;
		V_1 = L_3;
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF, (Il2CppByReference*)(&V_1));
		ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA L_5 = __this->____pointer;
		V_1 = L_5;
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF_m531E222DA3CEAB4F838160BE8BF0D076B903940C(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_m4FC4F99F9CE75AF1962CD853CBA05704DB24E740 (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71 ReadOnlySpan_1_Slice_m6141C6014D7DB6661E415A349F85CFC24AD39E29 (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71 L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_m66392F19D65D8E37FF8EFFBBA237A8B3CDBD1E3A_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71 ReadOnlySpan_1_Slice_mFB1FD51F619CED37AB98FE11ADA12E1A248CA654 (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_8;
		L_8 = il2cpp_unsafe_add<UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF,int32_t>(L_6, L_7, sizeof(UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71 L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_m66392F19D65D8E37FF8EFFBBA237A8B3CDBD1E3A_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6* ReadOnlySpan_1_ToArray_m5C43083C5EA83FFA854CE1025FE7BB19084088A6 (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6* L_1;
		L_1 = Array_Empty_TisUnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF_mEEAC43923BAB5402C351329E989F7E5FDBBC0E53_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6* L_3 = (UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6*)(UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_6;
		L_6 = il2cpp_unsafe_as_ref<UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF>(L_5);
		ByReference_1_t553CA63DD5902B8FA54B8D788F37D9BE79BFFBAA L_7 = __this->____pointer;
		V_0 = L_7;
		UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisUnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF_m531E222DA3CEAB4F838160BE8BF0D076B903940C(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_m5EA646D572B2CB430D29682121D2E767D0FC0E10 (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71 ___0_left, ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71 ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71 L_0 = ___0_left;
		ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71 L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_mE483F93046822C9468678DB29F761D3F06FF3C7E(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_mDFB15E52356B7B5B0BBC5DD55D37E73949CD4951 (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_m9E81D896EA507DF702BD1FF2F16365A0B0964CC6 (ReadOnlySpan_1_tB75D9F26DD2BD9AD7A09CB890238569A36CEAE71* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m5CC9461EEA62E6AFAF192130729ED899D96B29B3 (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185* __this, UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_12;
		L_12 = il2cpp_unsafe_as_ref<UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6>(L_11);
		int32_t L_13 = ___1_start;
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_14;
		L_14 = il2cpp_unsafe_add<UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6,int32_t>(L_12, L_13, sizeof(UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6));
		ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mB6C538A745906E2EEE476700D4A6CF9A9A92EB5D (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_2;
		L_2 = il2cpp_unsafe_as_ref<UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6>((uint8_t*)L_1);
		ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* ReadOnlySpan_1_get_Item_m11A070F8C669DF00BEBBAFCCE308167A62CE2414 (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_m9C9BB2ADE31A5E9AE88B1DC117EE7A21DA034566 (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185* __this, Span_1_tBF13F9501CCD12FFB2F5A59090DEA7BD31F5BDC7 ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mEF91E66E45055A28639FAA49F9338605E2E05F7C_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_tBF13F9501CCD12FFB2F5A59090DEA7BD31F5BDC7 L_2 = ___0_destination;
		ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 L_3 = L_2.____pointer;
		V_0 = L_3;
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6, (Il2CppByReference*)(&V_0));
		ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6_m6B7919683C297F7E18711B5748ED3690747AF645(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_m541B7430479FF42C6E99B081967334D54EAE91B4 (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185* __this, Span_1_tBF13F9501CCD12FFB2F5A59090DEA7BD31F5BDC7 ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mEF91E66E45055A28639FAA49F9338605E2E05F7C_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_tBF13F9501CCD12FFB2F5A59090DEA7BD31F5BDC7 L_2 = ___0_destination;
		ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 L_3 = L_2.____pointer;
		V_1 = L_3;
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6, (Il2CppByReference*)(&V_1));
		ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 L_5 = __this->____pointer;
		V_1 = L_5;
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6_m6B7919683C297F7E18711B5748ED3690747AF645(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_m2E4F1A19AB1855334C1547CF9ACE15DCD5F19115 (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185 ReadOnlySpan_1_Slice_mFA719902E1959E981FA51B31A52B996B8F6BE910 (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185 L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_m6C812749CD726114A53FA991ED2B2081E6A42C54_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185 ReadOnlySpan_1_Slice_m3F1CDD84C47D5AC4C38D0DDC665D6C9057C2A134 (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_8;
		L_8 = il2cpp_unsafe_add<UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6,int32_t>(L_6, L_7, sizeof(UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185 L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_m6C812749CD726114A53FA991ED2B2081E6A42C54_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8* ReadOnlySpan_1_ToArray_mE9BF1873C7223539CB354D755DF3E755893C1FA3 (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8* L_1;
		L_1 = Array_Empty_TisUnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6_m80635F8F2D3D0383C89E07968014ABC30ABEA62E_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8* L_3 = (UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8*)(UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_6;
		L_6 = il2cpp_unsafe_as_ref<UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6>(L_5);
		ByReference_1_tF56DCC6D4C5E0F4BA8E055DF4D7E79B7DB2ED299 L_7 = __this->____pointer;
		V_0 = L_7;
		UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisUnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6_m6B7919683C297F7E18711B5748ED3690747AF645(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_m347BD1CD824074BBC26EB1051075ECD277168123 (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185 ___0_left, ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185 ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185 L_0 = ___0_left;
		ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185 L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_m795ADA90BB856BC321715377F80986612F556D4C(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_mDEE0D8A5A525E6E8D8DF700D22F05FE391C20BF7 (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_m743C71EDA03D628765DAEBB14012ECAA95546ACC (ReadOnlySpan_1_tB6FE251575712C11FEE83B2E61559919FADC9185* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mE4CAB4D57E4C6E471E6A60C4799A21D30FB02B2D (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB* __this, UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_12;
		L_12 = il2cpp_unsafe_as_ref<UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4>(L_11);
		int32_t L_13 = ___1_start;
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_14;
		L_14 = il2cpp_unsafe_add<UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4,int32_t>(L_12, L_13, sizeof(UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4));
		ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mFBFA9E1B046147D3C522901F21C3C5F95F96C3A9 (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_2;
		L_2 = il2cpp_unsafe_as_ref<UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4>((uint8_t*)L_1);
		ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* ReadOnlySpan_1_get_Item_m5BAB7F8367BFD56799C9DAB924319B29C849EFAA (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_mBFE5760589371B72B121A0657E7DE957833CF600 (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB* __this, Span_1_t5546CD84F181EC350FB506984B90241364B8C8F6 ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mB346D5ACE2098245EF5F8BDB45CD7299937039AA_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t5546CD84F181EC350FB506984B90241364B8C8F6 L_2 = ___0_destination;
		ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 L_3 = L_2.____pointer;
		V_0 = L_3;
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4, (Il2CppByReference*)(&V_0));
		ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4_m43B235BFDAED5E73065C5516FB27FCE903846724(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_mB232D471E0491EC6B2B5B62ECD7745CE9FCF5917 (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB* __this, Span_1_t5546CD84F181EC350FB506984B90241364B8C8F6 ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mB346D5ACE2098245EF5F8BDB45CD7299937039AA_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t5546CD84F181EC350FB506984B90241364B8C8F6 L_2 = ___0_destination;
		ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 L_3 = L_2.____pointer;
		V_1 = L_3;
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4, (Il2CppByReference*)(&V_1));
		ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 L_5 = __this->____pointer;
		V_1 = L_5;
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4_m43B235BFDAED5E73065C5516FB27FCE903846724(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_m36141D2BD434E4019FE80411CD822DDE9FD76D94 (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB ReadOnlySpan_1_Slice_m6CE825274F8FB27E8FB35C7DFD51D5E851B2BD6B (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_mC0D0EA7EE88DAA315FBD8A84318719AB5E2BAA66_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB ReadOnlySpan_1_Slice_m3881951A18DF66F1782D779BB8EE5EC9D06FF08A (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_8;
		L_8 = il2cpp_unsafe_add<UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4,int32_t>(L_6, L_7, sizeof(UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_mC0D0EA7EE88DAA315FBD8A84318719AB5E2BAA66_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6* ReadOnlySpan_1_ToArray_mC89AF6BAE06006D4CAA441423BA863BB00C55DA4 (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6* L_1;
		L_1 = Array_Empty_TisUnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4_mF9B8EDAC651FA801E8CEE8280E4C2E9E9BC36096_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6* L_3 = (UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6*)(UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_6;
		L_6 = il2cpp_unsafe_as_ref<UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4>(L_5);
		ByReference_1_t69704F3A64F63EA5C746FF1EFED4B24034129174 L_7 = __this->____pointer;
		V_0 = L_7;
		UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisUnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4_m43B235BFDAED5E73065C5516FB27FCE903846724(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_m0335BE2D9DC8BC4528C9B72341862BBC11C45771 (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB ___0_left, ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB L_0 = ___0_left;
		ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_mD76E07AC17F959B55344C6E355DB9D0CEC31FC0C(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_m21A8FEDE18AF0F567A556E08E29F117929D7BDB7 (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_mDC82A3E60B9B2B00D89C73168BB8E9434EB111B8 (ReadOnlySpan_1_t86CCB719C2A553DFB7BAFF7E00E22CE413558FDB* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m1B5DCEC898FA002743A46CAE3EF79478280F2495 (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357* __this, UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_12;
		L_12 = il2cpp_unsafe_as_ref<UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A>(L_11);
		int32_t L_13 = ___1_start;
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_14;
		L_14 = il2cpp_unsafe_add<UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A,int32_t>(L_12, L_13, sizeof(UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A));
		ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mC063A887117628AF77F776F879E95FC3BF8CBE59 (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_2;
		L_2 = il2cpp_unsafe_as_ref<UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A>((uint8_t*)L_1);
		ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* ReadOnlySpan_1_get_Item_m22ADF866AFD450445C3D2F486B708A4576F31579 (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_mB69C78875838F393BDF5BB034069DA2320BC3A35 (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357* __this, Span_1_t460BF9A574BE0955E6E375F5EDC0E0830FA47381 ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m28C5FEE9DBE03CF72CF72C3E0CC494D3A9E9C233_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t460BF9A574BE0955E6E375F5EDC0E0830FA47381 L_2 = ___0_destination;
		ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 L_3 = L_2.____pointer;
		V_0 = L_3;
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A, (Il2CppByReference*)(&V_0));
		ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A_m3D68438A3C5FAE6C4F026A5954BEBC6157069B6E(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_m40AB691564D0BD700021FED7BB8FA32FC357FBD7 (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357* __this, Span_1_t460BF9A574BE0955E6E375F5EDC0E0830FA47381 ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m28C5FEE9DBE03CF72CF72C3E0CC494D3A9E9C233_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t460BF9A574BE0955E6E375F5EDC0E0830FA47381 L_2 = ___0_destination;
		ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 L_3 = L_2.____pointer;
		V_1 = L_3;
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A, (Il2CppByReference*)(&V_1));
		ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 L_5 = __this->____pointer;
		V_1 = L_5;
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A_m3D68438A3C5FAE6C4F026A5954BEBC6157069B6E(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_m63875ED1586E2AEA4E20F492EC777F59915B5873 (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357 ReadOnlySpan_1_Slice_m3C1994A1FB731B0263CA40C3B80EB49AA8F6A5BA (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357 L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_m05FAEE8A43921FFBDAA0B10C45DF7B413F8B7795_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357 ReadOnlySpan_1_Slice_mA22892A878DC4FF0A3F8C88DC34693C975450D5C (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_8;
		L_8 = il2cpp_unsafe_add<UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A,int32_t>(L_6, L_7, sizeof(UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357 L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_m05FAEE8A43921FFBDAA0B10C45DF7B413F8B7795_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD* ReadOnlySpan_1_ToArray_mDBBC462A167BABADD2E16326C5753AE64187F1CE (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD* L_1;
		L_1 = Array_Empty_TisUnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A_m19F4090BD5440974029AFE51BC45A5C37D4D5C77_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD* L_3 = (UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD*)(UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_6;
		L_6 = il2cpp_unsafe_as_ref<UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A>(L_5);
		ByReference_1_tFEC2183BE6E0D31202F7A12685DE0C72EDD622D8 L_7 = __this->____pointer;
		V_0 = L_7;
		UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisUnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A_m3D68438A3C5FAE6C4F026A5954BEBC6157069B6E(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_m49286FADA0F2B5C4A32BC6C39F788EB03BDD7A6F (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357 ___0_left, ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357 ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357 L_0 = ___0_left;
		ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357 L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_mB157614B5969EB80F641D18A4DB33C3D8FC885C1(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_m9B50B4F9892CB22144594508E242DB52CB78D11D (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_mA8AF62B0E177AAB66CE75AE6DC16854B9EC68618 (ReadOnlySpan_1_t696FE6F96AA7BCE8F69F5C7FA90443A2B6B40357* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m9EE5AA2C6F474A87EDBC562FEFDD5E3614E91AF2 (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E* __this, UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_12;
		L_12 = il2cpp_unsafe_as_ref<UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73>(L_11);
		int32_t L_13 = ___1_start;
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_14;
		L_14 = il2cpp_unsafe_add<UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73,int32_t>(L_12, L_13, sizeof(UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73));
		ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m1C1AC064655CAD3B5FE879FA16B9D02D297E1DB2 (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_2;
		L_2 = il2cpp_unsafe_as_ref<UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73>((uint8_t*)L_1);
		ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* ReadOnlySpan_1_get_Item_m2755AC34B6E32D581F15332969A2D9E54160BB11 (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_m9BE39284B4F812AB263BA19A88318986400FC72B (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E* __this, Span_1_t9DA7921D616AFD6EFF2CEF642A21C62ED20C6F05 ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m9BA78DAEE8653BAD2B9ADFFE2B50A419DBA0E47E_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t9DA7921D616AFD6EFF2CEF642A21C62ED20C6F05 L_2 = ___0_destination;
		ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 L_3 = L_2.____pointer;
		V_0 = L_3;
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73, (Il2CppByReference*)(&V_0));
		ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73_mBDCCC7D03D4C397E8F32FB955EC547A2FDFA5543(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_m71433EFC5A729908EC988E037934232310A2D120 (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E* __this, Span_1_t9DA7921D616AFD6EFF2CEF642A21C62ED20C6F05 ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m9BA78DAEE8653BAD2B9ADFFE2B50A419DBA0E47E_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t9DA7921D616AFD6EFF2CEF642A21C62ED20C6F05 L_2 = ___0_destination;
		ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 L_3 = L_2.____pointer;
		V_1 = L_3;
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73, (Il2CppByReference*)(&V_1));
		ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 L_5 = __this->____pointer;
		V_1 = L_5;
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73_mBDCCC7D03D4C397E8F32FB955EC547A2FDFA5543(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_m4DCC3446A0972B5568A9C2D559BD1FB89D439561 (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E ReadOnlySpan_1_Slice_m227FB23C675EE7DA0C8C0D20C490376156129AEE (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_m189B1065E7F68FCEFFD8B51369EE9310DF43AB4E_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E ReadOnlySpan_1_Slice_mDDD26BD2D19FD5F1FF4811DEAB57D910978BC2D7 (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_8;
		L_8 = il2cpp_unsafe_add<UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73,int32_t>(L_6, L_7, sizeof(UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_m189B1065E7F68FCEFFD8B51369EE9310DF43AB4E_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00* ReadOnlySpan_1_ToArray_mB121B5A1EE07998B898C2D5A302E1CAC335FACA9 (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00* L_1;
		L_1 = Array_Empty_TisUnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73_m38077BA7106C32737B0A147A292DAA166A65A743_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00* L_3 = (UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00*)(UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_6;
		L_6 = il2cpp_unsafe_as_ref<UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73>(L_5);
		ByReference_1_t6DE5AAABB959B9270B2A107245588A5D9FD5DC10 L_7 = __this->____pointer;
		V_0 = L_7;
		UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisUnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73_mBDCCC7D03D4C397E8F32FB955EC547A2FDFA5543(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_m5E2294260132AC089CF5D1ABFD9D32E121E34E23 (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E ___0_left, ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E L_0 = ___0_left;
		ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_m3EDB78E2FEE1B7D258823CFA9B42822972E7004D(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_m61D449DCB07C9226893B6D705D174CEB5D127A7F (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_m5F0F1ECA65F9CD0E78582FDF37B78EBCB2FC1B98 (ReadOnlySpan_1_tF8DAF2B7A0E7DD5B50B12D3B4ADBCB3E2876117E* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m663A49222CE5B63BDF17D1F044B147F16CA6B52D (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5* __this, UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_12;
		L_12 = il2cpp_unsafe_as_ref<UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516>(L_11);
		int32_t L_13 = ___1_start;
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_14;
		L_14 = il2cpp_unsafe_add<UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516,int32_t>(L_12, L_13, sizeof(UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516));
		ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m8C9ABF07F53204CEF3BC66717957E9FB9079144B (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_2;
		L_2 = il2cpp_unsafe_as_ref<UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516>((uint8_t*)L_1);
		ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* ReadOnlySpan_1_get_Item_m733DBEC1997736918F81804AE8D15E33A9801B3C (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_m32C570A8CB721B220B83BC9728173BF3FBA8ED5A (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5* __this, Span_1_t83DEC692D54FF8BED9317442919944F109D8D9FB ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m45281C7FCFF81C6F91B1E8B0897FDFC91AB9AB2E_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t83DEC692D54FF8BED9317442919944F109D8D9FB L_2 = ___0_destination;
		ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 L_3 = L_2.____pointer;
		V_0 = L_3;
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516, (Il2CppByReference*)(&V_0));
		ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516_m996D3C06C347B6A640186D2FAC8C066B5DD1AAC2(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_mA86201860528C3418A58EB4EF6602D54E9AF015D (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5* __this, Span_1_t83DEC692D54FF8BED9317442919944F109D8D9FB ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m45281C7FCFF81C6F91B1E8B0897FDFC91AB9AB2E_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t83DEC692D54FF8BED9317442919944F109D8D9FB L_2 = ___0_destination;
		ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 L_3 = L_2.____pointer;
		V_1 = L_3;
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516, (Il2CppByReference*)(&V_1));
		ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 L_5 = __this->____pointer;
		V_1 = L_5;
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516_m996D3C06C347B6A640186D2FAC8C066B5DD1AAC2(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_m159BC7A611E225103CE6328AF7378722051FDF8A (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5 ReadOnlySpan_1_Slice_m9EB8BAFB47885F213AB056406CD45AC774917A7B (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5 L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_mC5370B060FD7B513D4E024C074C86F97DBAFBB17_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5 ReadOnlySpan_1_Slice_m342C30CF931B104227DB89ACDA0B255A8037DBCA (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_8;
		L_8 = il2cpp_unsafe_add<UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516,int32_t>(L_6, L_7, sizeof(UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5 L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_mC5370B060FD7B513D4E024C074C86F97DBAFBB17_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB* ReadOnlySpan_1_ToArray_m7DE1C45CC2CD5BC193168141AE3E7256EB2FB4C0 (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB* L_1;
		L_1 = Array_Empty_TisUnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516_m2559F4EE41A1BC5F7F6D91695D46A1FFB8292C19_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB* L_3 = (UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB*)(UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_6;
		L_6 = il2cpp_unsafe_as_ref<UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516>(L_5);
		ByReference_1_tDBC52CE13CB5F6C96F41D19B1F960D4BDEF4BE23 L_7 = __this->____pointer;
		V_0 = L_7;
		UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisUnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516_m996D3C06C347B6A640186D2FAC8C066B5DD1AAC2(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_mDBE97D041CE0AA7A2316CF8043735500764E316F (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5 ___0_left, ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5 ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5 L_0 = ___0_left;
		ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5 L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_mD2406E85102C4510337D5938C7775580D1FD07B6(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_m2576FF32D5643F19BFBD12C4164C49D6973F2708 (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_mEA8D4EC603889E4C3361BEA8B6840650D8F431C9 (ReadOnlySpan_1_t51A82B8CA8400B5D03100B09202DC5C6C6E65DD5* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mCF451D151DB4110395494814A49B02AED43E87DD (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8* __this, UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_12;
		L_12 = il2cpp_unsafe_as_ref<UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB>(L_11);
		int32_t L_13 = ___1_start;
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_14;
		L_14 = il2cpp_unsafe_add<UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB,int32_t>(L_12, L_13, sizeof(UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB));
		ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mBB716384CCFAC02BB5D40DB67B250F0EED49C91F (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_2;
		L_2 = il2cpp_unsafe_as_ref<UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB>((uint8_t*)L_1);
		ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* ReadOnlySpan_1_get_Item_mB83A55D8B8541EC6E5BCA54EAA5CB4F551E9EB59 (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_m239DA3C2107580D94BEE7801DB88D5E0D81964FE (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8* __this, Span_1_t6BF1EBB3CB6E0BEE5E6E144F0324DFB047F18F32 ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mA59EA29AF3DD0FC655679A6085EE47B82CF64D41_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t6BF1EBB3CB6E0BEE5E6E144F0324DFB047F18F32 L_2 = ___0_destination;
		ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 L_3 = L_2.____pointer;
		V_0 = L_3;
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB, (Il2CppByReference*)(&V_0));
		ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB_m12DF3FA9D7727285D808AAECE8E2786E166C62EC(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_mE5D0AC06F12A8CDCB02CCE061EACC1F0A4B6266A (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8* __this, Span_1_t6BF1EBB3CB6E0BEE5E6E144F0324DFB047F18F32 ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_mA59EA29AF3DD0FC655679A6085EE47B82CF64D41_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t6BF1EBB3CB6E0BEE5E6E144F0324DFB047F18F32 L_2 = ___0_destination;
		ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 L_3 = L_2.____pointer;
		V_1 = L_3;
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB, (Il2CppByReference*)(&V_1));
		ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 L_5 = __this->____pointer;
		V_1 = L_5;
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB_m12DF3FA9D7727285D808AAECE8E2786E166C62EC(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_mFB6006EA4762F1F49DDC87E921F045BEBF04403F (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8 ReadOnlySpan_1_Slice_m8B9E9DB3503009E612504B5B83548E44C11DF216 (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8 L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_m7E4F150F2960FADBE911D19F7D28C3988BA704BE_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8 ReadOnlySpan_1_Slice_m85F65B9E5FCB8D26261463F13EA8DE87A5FEB6B1 (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_8;
		L_8 = il2cpp_unsafe_add<UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB,int32_t>(L_6, L_7, sizeof(UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8 L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_m7E4F150F2960FADBE911D19F7D28C3988BA704BE_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06* ReadOnlySpan_1_ToArray_m5A1DC60F6D14DBF3D31ED6C1793A7480791E0C20 (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06* L_1;
		L_1 = Array_Empty_TisUnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB_m198A5A706220D5563451F5718452BA9A56A72461_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06* L_3 = (UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06*)(UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_6;
		L_6 = il2cpp_unsafe_as_ref<UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB>(L_5);
		ByReference_1_t9A5DCB50A02F4DA469C43B3E0FDD73D2663B7B82 L_7 = __this->____pointer;
		V_0 = L_7;
		UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisUnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB_m12DF3FA9D7727285D808AAECE8E2786E166C62EC(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_mF58E87AD91D70CF3FE32CA4EB545D133C5937D12 (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8 ___0_left, ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8 ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8 L_0 = ___0_left;
		ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8 L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_m9821AF644D61E565E36E9E2E52222A7DA94FA0B7(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_m485F2D498ED5CC2FAB33AF7977EC34989B86584F (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_m51AF93EA120E53D0500DB0ACF77A1C989D494703 (ReadOnlySpan_1_t6A5547B1FE955322F0DE533A092096B0843D4CF8* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"
#pragma clang diagnostic ignored "-Wunused-variable"
#endif
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m28B5905411D0BEB6E63558531E9AD8B14CE79BF0 (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8* __this, UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_12;
		L_12 = il2cpp_unsafe_as_ref<UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8>(L_11);
		int32_t L_13 = ___1_start;
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_14;
		L_14 = il2cpp_unsafe_add<UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8,int32_t>(L_12, L_13, sizeof(UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8));
		ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m28EE017FC71211F1CB63FC89EACC31FE1759F89C (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8* __this, void* ___0_pointer, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		goto IL_0016;
	}

IL_0016:
	{
		int32_t L_0 = ___1_length;
		if ((((int32_t)L_0) >= ((int32_t)0)))
		{
			goto IL_001f;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_001f:
	{
		void* L_1 = ___0_pointer;
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_2;
		L_2 = il2cpp_unsafe_as_ref<UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8>((uint8_t*)L_1);
		ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 L_3;
		memset((&L_3), 0, sizeof(L_3));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_3), L_2);
		__this->____pointer = L_3;
		int32_t L_4 = ___1_length;
		__this->____length = L_4;
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* ReadOnlySpan_1_get_Item_m94473C3081F53D656C3B5B814223CCB9E6C4D126 (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8* __this, int32_t ___0_index, const RuntimeMethod* method) 
{
	ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_index;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) >= ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowIndexOutOfRangeException_m86F753A24E2765A35546BA6352A7E4F0BB8A66B5(NULL);
	}

IL_000e:
	{
		ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_index;
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8));
		return L_5;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR void ReadOnlySpan_1_CopyTo_m0AECA35F475B3B34D09F55BD84FE22460717A6E3 (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8* __this, Span_1_t399B9EFF21D03E62E3B6A8591A5B91D4B44A6649 ___0_destination, const RuntimeMethod* method) 
{
	ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m851E7466A7ADB4DA5BD951798802A989624EC76C_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0038;
		}
	}
	{
		Span_1_t399B9EFF21D03E62E3B6A8591A5B91D4B44A6649 L_2 = ___0_destination;
		ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 L_3 = L_2.____pointer;
		V_0 = L_3;
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8, (Il2CppByReference*)(&V_0));
		ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8, (Il2CppByReference*)(&V_0));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8_mB0F180342B1F4A1D35E400B23C6B7CAF85F63CD2(L_4, L_6, L_8, NULL);
		return;
	}

IL_0038:
	{
		ThrowHelper_ThrowArgumentException_DestinationTooShort_m6468934A3BBB67DBC5BAEF7A64D91BD5BBBB3D4D(NULL);
		return;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_TryCopyTo_m9C4E48D8238A8B402F8603126D44905BF922B7FE (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8* __this, Span_1_t399B9EFF21D03E62E3B6A8591A5B91D4B44A6649 ___0_destination, const RuntimeMethod* method) 
{
	bool V_0 = false;
	ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		V_0 = (bool)0;
		int32_t L_0 = __this->____length;
		int32_t L_1;
		L_1 = Span_1_get_Length_m851E7466A7ADB4DA5BD951798802A989624EC76C_inline((&___0_destination), NULL);
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_003b;
		}
	}
	{
		Span_1_t399B9EFF21D03E62E3B6A8591A5B91D4B44A6649 L_2 = ___0_destination;
		ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 L_3 = L_2.____pointer;
		V_1 = L_3;
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_4;
		L_4 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8, (Il2CppByReference*)(&V_1));
		ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 L_5 = __this->____pointer;
		V_1 = L_5;
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8, (Il2CppByReference*)(&V_1));
		int32_t L_7 = __this->____length;
		int64_t L_8 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_7,NULL));
		Buffer_Memmove_TisUnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8_mB0F180342B1F4A1D35E400B23C6B7CAF85F63CD2(L_4, L_6, L_8, NULL);
		V_0 = (bool)1;
	}

IL_003b:
	{
		bool L_9 = V_0;
		return L_9;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR String_t* ReadOnlySpan_1_ToString_m97CCA9165BE676279A34C83977DE4E57ED959DDE (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8* __this, const RuntimeMethod* method) 
{
	static bool s_Il2CppMethodInitialized;
	if (!s_Il2CppMethodInitialized)
	{
		il2cpp_codegen_initialize_runtime_metadata((uintptr_t*)&_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D);
		s_Il2CppMethodInitialized = true;
	}
	CHECKED_LOCAL(classRgctxInit);
	CHECKED_LOCAL(Type_t_StaticInit);
	Il2CppChar* V_0 = NULL;
	ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 V_1;
	memset((&V_1), 0, sizeof(V_1));
	{
		goto IL_003e;
	}

IL_003e:
	{
		RuntimeTypeHandle_t332A452B8B6179E4469B69525D0FE82A88030F7B L_0 = { reinterpret_cast<intptr_t> (il2cpp_rgctx_type(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 3)) };
		CHECKED_LOCAL_INIT(Type_t_StaticInit,(Type_t_il2cpp_TypeInfo_var),il2cpp_codegen_runtime_class_init_inline);
		Type_t* L_1;
		L_1 = Type_GetTypeFromHandle_m6062B81682F79A4D6DF2640692EE6D9987858C57(L_0, NULL);
		NullCheck(L_1);
		String_t* L_2;
		L_2 = VirtualFuncInvoker0< String_t* >::Invoke(8, L_1);
		int32_t L_3 = __this->____length;
		int32_t L_4 = L_3;
		RuntimeObject* L_5 = Box(Int32_t680FF22E76F6EFAD4375103CBBFFA0421349384C_il2cpp_TypeInfo_var, &L_4);
		String_t* L_6;
		L_6 = String_Format_mFB7DA489BD99F4670881FF50EC017BFB0A5C0987(_stringLiteral2DCA6040AD5A31C81EBE664FAFD10DAFB1B1CD5D, L_2, L_5, NULL);
		return L_6;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8 ReadOnlySpan_1_Slice_m32C3665F28336C594238613FF77ED20A61628C0E (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8* __this, int32_t ___0_start, const RuntimeMethod* method) 
{
	ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) > ((uint32_t)L_1))))
		{
			goto IL_000e;
		}
	}
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 L_2 = __this->____pointer;
		V_0 = L_2;
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_3;
		L_3 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8, (Il2CppByReference*)(&V_0));
		int32_t L_4 = ___0_start;
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_5;
		L_5 = il2cpp_unsafe_add<UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8,int32_t>(L_3, L_4, sizeof(UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8));
		int32_t L_6 = __this->____length;
		int32_t L_7 = ___0_start;
		ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8 L_8;
		memset((&L_8), 0, sizeof(L_8));
		ReadOnlySpan_1__ctor_mC62CC2AF726A0EEE2B165E13BA155A4B09311BC8_inline((&L_8), L_5, ((int32_t)il2cpp_codegen_subtract(L_6, L_7)), NULL);
		return L_8;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8 ReadOnlySpan_1_Slice_mD8ECF1E91A9A78D391C68E7915D802D73ABC253D (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 L_5 = __this->____pointer;
		V_0 = L_5;
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_8;
		L_8 = il2cpp_unsafe_add<UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8,int32_t>(L_6, L_7, sizeof(UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8));
		int32_t L_9 = ___1_length;
		ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8 L_10;
		memset((&L_10), 0, sizeof(L_10));
		ReadOnlySpan_1__ctor_mC62CC2AF726A0EEE2B165E13BA155A4B09311BC8_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B* ReadOnlySpan_1_ToArray_mF03DD27E3F2BBABF724426AAD1B23E1C3552BACC (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8* __this, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = __this->____length;
		if (L_0)
		{
			goto IL_000e;
		}
	}
	{
		UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B* L_1;
		L_1 = Array_Empty_TisUnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8_mBB7951BE7C90C20D302AF78E7CD56927C0AE123D_inline(il2cpp_rgctx_method(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 7));
		return L_1;
	}

IL_000e:
	{
		int32_t L_2 = __this->____length;
		UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B* L_3 = (UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B*)(UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B*)SZArrayNew(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 8), (uint32_t)L_2);
		UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B* L_4 = L_3;
		NullCheck((RuntimeArray*)L_4);
		uint8_t* L_5;
		L_5 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_4, NULL);
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_6;
		L_6 = il2cpp_unsafe_as_ref<UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8>(L_5);
		ByReference_1_t3F9ED5323AD7C21E60591D10B21B5E9D010A0EF9 L_7 = __this->____pointer;
		V_0 = L_7;
		UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8* L_8;
		L_8 = IL2CPP_BY_REFERENCE_GET_VALUE(UnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8, (Il2CppByReference*)(&V_0));
		int32_t L_9 = __this->____length;
		int64_t L_10 = (il2cpp_codegen_conv<int64_t,int32_t,int32_t,false,false>(L_9,NULL));
		Buffer_Memmove_TisUnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8_mB0F180342B1F4A1D35E400B23C6B7CAF85F63CD2(L_6, L_8, L_10, NULL);
		return L_4;
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_op_Inequality_mE6DBF0D5B36596E5E2BABD6D9607890E0FC8EE90 (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8 ___0_left, ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8 ___1_right, const RuntimeMethod* method) 
{
	{
		ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8 L_0 = ___0_left;
		ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8 L_1 = ___1_right;
		bool L_2;
		L_2 = ReadOnlySpan_1_op_Equality_m4C28BFFAE59CC4D76A555A76D09850EE697F895B(L_0, L_1, NULL);
		return (bool)((((int32_t)L_2) == ((int32_t)0))? 1 : 0);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR bool ReadOnlySpan_1_Equals_mF7412D13FBE047FC4310E0EFF78A6A0910811CD3 (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8* __this, RuntimeObject* ___0_obj, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteral69508A540AFD085A745316DD7D6345B1C8CC662D)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
IL2CPP_EXTERN_C IL2CPP_METHOD_ATTR int32_t ReadOnlySpan_1_GetHashCode_m3D973E9E6DC61F2061C42D77283C571BB9477FE8 (ReadOnlySpan_1_t8DCE96E6E6E5C0D9D7228349BFF0EF7F8E5AABC8* __this, const RuntimeMethod* method) 
{
	{
		NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A* L_0 = (NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A*)il2cpp_codegen_object_new(((RuntimeClass*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&NotSupportedException_t1429765983D409BD2986508963C98D214E4EBF4A_il2cpp_TypeInfo_var)));
		NotSupportedException__ctor_mE174750CF0247BBB47544FFD71D66BB89630945B(L_0, ((String_t*)il2cpp_codegen_initialize_runtime_metadata_inline((uintptr_t*)&_stringLiteralECE618215BAC99C6FD12D8A273CC2118945EDCC8)), NULL);
		IL2CPP_RAISE_MANAGED_EXCEPTION(L_0, method);
	}
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR int32_t String_get_Length_m42625D67623FA5CC7A44D47425CE86FB946542D2_inline (String_t* __this, const RuntimeMethod* method) 
{
	{
		int32_t L_0 = __this->____stringLength;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR uint8_t* Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline (RuntimeArray* __this, const RuntimeMethod* method) 
{
	{
		RawData_t37CAF2D3F74B7723974ED7CEEE9B297D8FA64ED0* L_0;
		L_0 = il2cpp_unsafe_as<RawData_t37CAF2D3F74B7723974ED7CEEE9B297D8FA64ED0*>(__this);
		NullCheck(L_0);
		uint8_t* L_1 = (uint8_t*)(&L_0->___Data);
		return L_1;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305 Span_1_Slice_m9D8BA8245B8DC9BFB4A4164759CBAAEAD1318CD6_inline (Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305* __this, int32_t ___0_start, int32_t ___1_length, const RuntimeMethod* method) 
{
	ByReference_1_t9C85BCCAAF8C525B6C06B07E922D8D217BE8D6FC V_0;
	memset((&V_0), 0, sizeof(V_0));
	{
		int32_t L_0 = ___0_start;
		int32_t L_1 = __this->____length;
		if ((!(((uint32_t)L_0) <= ((uint32_t)L_1))))
		{
			goto IL_0014;
		}
	}
	{
		int32_t L_2 = ___1_length;
		int32_t L_3 = __this->____length;
		int32_t L_4 = ___0_start;
		if ((!(((uint32_t)L_2) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_3, L_4))))))
		{
			goto IL_0019;
		}
	}

IL_0014:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0019:
	{
		ByReference_1_t9C85BCCAAF8C525B6C06B07E922D8D217BE8D6FC L_5 = __this->____pointer;
		V_0 = L_5;
		uint8_t* L_6;
		L_6 = IL2CPP_BY_REFERENCE_GET_VALUE(uint8_t, (Il2CppByReference*)(&V_0));
		int32_t L_7 = ___0_start;
		uint8_t* L_8;
		L_8 = il2cpp_unsafe_add<uint8_t,int32_t>(L_6, L_7, sizeof(uint8_t));
		int32_t L_9 = ___1_length;
		Span_1_tDADAC65069DFE6B57C458109115ECD795ED39305 L_10;
		memset((&L_10), 0, sizeof(L_10));
		Span_1__ctor_m947BF95D54571BF3897F96822B7A8FDA5853497B_inline((&L_10), L_8, L_9, NULL);
		return L_10;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_m7B5C2765879EA5E8D1617D834CC465A39540A913_inline (ReadOnlySpan_1_tA850A6C0E88ABBA37646A078ACBC24D6D5FD9B4D* __this, ByteU5BU5D_tA6237BF417AE52AD70CFB4EF24A7A82613DF9031* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	{
		ByteU5BU5D_tA6237BF417AE52AD70CFB4EF24A7A82613DF9031* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_tA850A6C0E88ABBA37646A078ACBC24D6D5FD9B4D));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		ByteU5BU5D_tA6237BF417AE52AD70CFB4EF24A7A82613DF9031* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		ByteU5BU5D_tA6237BF417AE52AD70CFB4EF24A7A82613DF9031* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		ByteU5BU5D_tA6237BF417AE52AD70CFB4EF24A7A82613DF9031* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		uint8_t* L_12;
		L_12 = il2cpp_unsafe_as_ref<uint8_t>(L_11);
		int32_t L_13 = ___1_start;
		uint8_t* L_14;
		L_14 = il2cpp_unsafe_add<uint8_t,int32_t>(L_12, L_13, sizeof(uint8_t));
		ByReference_1_t9C85BCCAAF8C525B6C06B07E922D8D217BE8D6FC L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mFA6EE52BCF39100AE30C79E73F0F972182D0CA2A_fshared_inline (ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC* __this, Il2CppFullySharedGenericAny* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		Il2CppFullySharedGenericAny* L_0 = ___0_ptr;
		ByReference_1_t607C1F3BC28B0E21B969461CDB0720FB01A82141 L_1;
		memset((&L_1), 0, sizeof(L_1));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_1), L_0);
		__this->____pointer = L_1;
		int32_t L_2 = ___1_length;
		__this->____length = L_2;
		return;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR void ReadOnlySpan_1__ctor_mC9869776ABBFE9D2520512EEB39ABD1CFFE7F7B9_fshared_inline (ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC* __this, __Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC* ___0_array, int32_t ___1_start, int32_t ___2_length, const RuntimeMethod* method) 
{
	CHECKED_LOCAL(classRgctxInit);
	const uint32_t SizeOf_T_t120950580BDFD368223E024446019DB239080837 = il2cpp_codegen_sizeof(il2cpp_rgctx_data(CHECKED_LOCAL_INIT_PARAM(classRgctxInit,(il2cpp_codegen_method_rgctx(method)),il2cpp_codegen_initialized_method_rgctx,(method)), 1));
	{
		__Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC* L_0 = ___0_array;
		if (L_0)
		{
			goto IL_0016;
		}
	}
	{
		int32_t L_1 = ___1_start;
		if (L_1)
		{
			goto IL_0009;
		}
	}
	{
		int32_t L_2 = ___2_length;
		if (!L_2)
		{
			goto IL_000e;
		}
	}

IL_0009:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_000e:
	{
		il2cpp_codegen_initobj(__this, sizeof(ReadOnlySpan_1_tC416A5627E04F69CA2947A2A13F0A1DF096CABAC));
		return;
	}

IL_0016:
	{
		int32_t L_3 = ___1_start;
		__Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC* L_4 = ___0_array;
		NullCheck(L_4);
		int32_t L_5 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_4)->max_length),NULL));
		if ((!(((uint32_t)L_3) <= ((uint32_t)L_5))))
		{
			goto IL_0024;
		}
	}
	{
		int32_t L_6 = ___2_length;
		__Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC* L_7 = ___0_array;
		NullCheck(L_7);
		int32_t L_8 = (il2cpp_codegen_conv<int32_t,int64_t,int64_t,false,false>((((RuntimeArray*)L_7)->max_length),NULL));
		int32_t L_9 = ___1_start;
		if ((!(((uint32_t)L_6) > ((uint32_t)((int32_t)il2cpp_codegen_subtract(L_8, L_9))))))
		{
			goto IL_0029;
		}
	}

IL_0024:
	{
		ThrowHelper_ThrowArgumentOutOfRangeException_mD7D90276EDCDF9394A8EA635923E3B48BB71BD56(NULL);
	}

IL_0029:
	{
		__Il2CppFullySharedGenericTypeU5BU5D_tCAB6D060972DD49223A834B7EEFEB9FE2D003BEC* L_10 = ___0_array;
		NullCheck((RuntimeArray*)L_10);
		uint8_t* L_11;
		L_11 = Array_GetRawSzArrayData_m2F8F5B2A381AEF971F12866D9C0A6C4FBA59F6BB_inline((RuntimeArray*)L_10, NULL);
		Il2CppFullySharedGenericAny* L_12;
		L_12 = il2cpp_unsafe_as_ref<Il2CppFullySharedGenericAny>(L_11);
		int32_t L_13 = ___1_start;
		Il2CppFullySharedGenericAny* L_14;
		L_14 = il2cpp_unsafe_add<Il2CppFullySharedGenericAny,int32_t>(L_12, L_13, SizeOf_T_t120950580BDFD368223E024446019DB239080837);
		ByReference_1_t607C1F3BC28B0E21B969461CDB0720FB01A82141 L_15;
		memset((&L_15), 0, sizeof(L_15));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_15), L_14);
		__this->____pointer = L_15;
		int32_t L_16 = ___2_length;
		__this->____length = L_16;
		return;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR int32_t Span_1_get_Length_m4CED98A19744D579382FDCEDEF16DBC11586BE1C_fshared_inline (Span_1_tDEB40BEFA77B5E4BB49B058CD3050EEA4DD36C54* __this, const RuntimeMethod* method) 
{
	{
		int32_t L_0 = __this->____length;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA* Array_Empty_TisEmbeddedArray32_1_tB435A10C3DB5E0B01F53C5CF569FEF40BB061A96_mD229BDA583D562BD2A433878A338C82536F745F3_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		EmbeddedArray32_1U5BU5D_t2E3146649D7134B048D388505F182F203AC3A6AA* L_0 = ((EmptyArray_1_tBCCAE4080E81992F81CEC3B682CED9E81A3B4D67_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* Array_Empty_TisHashEntry_1_t0CF7FFD9BDEAB90BD66EEB375F4933A8AAFA09A5_m7546ECBE8AAEBE56E0F447E66B1A47851A568FCC_gshared_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		HashEntry_1U5BU5D_t824A58AA39DA3EA6BB6A4E34CA6440B5CA88A5D5* L_0 = ((EmptyArray_1_tF44AD9BD1A58C47BDCB13A8D4D22873C785CC3F8_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0* Array_Empty_TisNativeArray_1_t3C666A50D3E0F5803B63036EC771A974D48FFF62_mBDB8DDE2D2948EDF2432FC77141B7D1360CDA732_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		NativeArray_1U5BU5D_tBE79B4E31CFB931AC204F3F4DE7B0FEC2BF1E8C0* L_0 = ((EmptyArray_1_t4505232400AEC5D181E96238357D9ACD1C992762_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06* Array_Empty_TisSelectorWorkItem_tBF6E4B85CACDC4734FBEAF1530157885BA83A474_m4433599FD227186796BAB47DC5BED2AF106ED67E_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		SelectorWorkItemU5BU5D_tD4000858C14565D18EFA0D397ECB4A37841FDE06* L_0 = ((EmptyArray_1_t0542F0EB5C43D54C8F4ADCAB1E94F18AEA151867_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C* Array_Empty_TisUnsafeList_1_tBC87D2EA47419434CBF8C62B9720C3429D1B20FD_m14FA981EC22CA08E194019E3506AD1ABB6322E6D_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		UnsafeList_1U5BU5D_t2592182F7B3D62F7A8F574454DC0C2E05B0E8C3C* L_0 = ((EmptyArray_1_tC9589F12F2382131419143780EC4B16F75839727_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A* Array_Empty_TisUnsafeList_1_t5C65DCA6782B7C9860C859C2F0C07A2C497E822D_mB80BD27875E5AD9B06C08FC9D673F81494E06C0D_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		UnsafeList_1U5BU5D_t621C634A191E0E89228A3B737E8E3E1F1270E30A* L_0 = ((EmptyArray_1_t39CC4801B12BC59D744D8F2F14920ED998228BE1_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B* Array_Empty_TisUnsafeList_1_t29F8EF14D6774A9F0BAD6E9C08A5123B993D1692_m8225D086EDE4F1EA4A744724F13D762BD6A7FFA2_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		UnsafeList_1U5BU5D_t1F52019D6B13F2A8C95B8312C94AD235C54DDE7B* L_0 = ((EmptyArray_1_t8F16BED9A16610B0610D3B8977C56192C7CE8275_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC* Array_Empty_TisUnsafeList_1_t239C74D869DA59B0CA5E63716E71208DEC68A70B_mD5A5585240A77F26BE14BF51B1F8B7C2259B0019_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		UnsafeList_1U5BU5D_t0B2E344DD41577BF29822F7B3CA67FD60582CAFC* L_0 = ((EmptyArray_1_tE873052363E5FFF3E3324D48BF2E70EABF9FBA3E_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1* Array_Empty_TisUnsafeList_1_t778B2F7252E312B13D6246FDF11E43D9830882D0_m81189A63B159A0BC9CF1D06BCB85661915D86FEB_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		UnsafeList_1U5BU5D_tD89AFF832AC2753A9EF66ADFF1D26116065DC5A1* L_0 = ((EmptyArray_1_tE694D0227F619BC5A10811AC94E5B6D8EE0CBD57_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3* Array_Empty_TisUnsafeList_1_t6C5E84D303190B625F3759C244502E1735453718_m6DEB24EE574A3109DB94AA1CFC7A5BA936F84D38_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		UnsafeList_1U5BU5D_t833820DBD583C4C49FAC0123A63D3617D808E9B3* L_0 = ((EmptyArray_1_tA05DBCB91EE064FE54203B7543F218C61D4C292D_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6* Array_Empty_TisUnsafeList_1_t6536D7A9C34D38B0421BA85AC9793E0F14F65CCF_mEEAC43923BAB5402C351329E989F7E5FDBBC0E53_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		UnsafeList_1U5BU5D_tA8674C465A6BD8BA88FA33D496BA0DDC761FDCA6* L_0 = ((EmptyArray_1_tFEE1A4E0C8058B54F07835CFB63F231873095076_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8* Array_Empty_TisUnsafeList_1_t86E1B55915C0B6CE8368236B0D8EDB80B7D396D6_m80635F8F2D3D0383C89E07968014ABC30ABEA62E_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		UnsafeList_1U5BU5D_tC00A6FD5AB7214DF0DF79FB98F7F35104D2FB0B8* L_0 = ((EmptyArray_1_t8505E6935DD4C58400550971BB8321BD8CE9D6CF_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6* Array_Empty_TisUnsafeList_1_t414FED53EC4FCC224CD6E9501F375B71ACC6C6F4_mF9B8EDAC651FA801E8CEE8280E4C2E9E9BC36096_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		UnsafeList_1U5BU5D_t5D6BFB4281F1114557DAA316EE93852F1C7C44D6* L_0 = ((EmptyArray_1_tA0B73630739AC85F81DDEFE547CAFB1C84FB72C6_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD* Array_Empty_TisUnsafeList_1_t0019D98C6D95AF9C6414C149BAA15CBBCC837C8A_m19F4090BD5440974029AFE51BC45A5C37D4D5C77_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		UnsafeList_1U5BU5D_t33CA11850507E252617672781F161E215A47A7AD* L_0 = ((EmptyArray_1_t1347A16AC3E72AFF909DAA98EED1FA11A4470068_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00* Array_Empty_TisUnsafeList_1_t453075A075D99649F8B3C2ED564085F6F2036D73_m38077BA7106C32737B0A147A292DAA166A65A743_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		UnsafeList_1U5BU5D_tD80EAF8442A3FD67A1B95323EAB0DBBF2B70AF00* L_0 = ((EmptyArray_1_t5058CECA8099AD79767245351D26A5CB48C84746_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB* Array_Empty_TisUnsafeList_1_t0B514D46EF09CD2AD227C46904D4A19A6BCD3516_m2559F4EE41A1BC5F7F6D91695D46A1FFB8292C19_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		UnsafeList_1U5BU5D_tB6FB30BCFA360D4DBA55B9B2866F28A0B61155CB* L_0 = ((EmptyArray_1_t47AB7FAF9E162BBE81FCF7964F3209ECF415B0A4_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06* Array_Empty_TisUnsafeList_1_t7A543190DA1A83E02E2B1A875EA82180D6B548AB_m198A5A706220D5563451F5718452BA9A56A72461_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		UnsafeList_1U5BU5D_t6CAC8C8DBA8B49792EA525D6A221596C0985CC06* L_0 = ((EmptyArray_1_t410AE8CFE5DA7B6BD5DA6669225E54549802E603_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B* Array_Empty_TisUnsafeList_1_t654D4A1DC3B0AE23EEBE8B889AD312E67B96BEB8_mBB7951BE7C90C20D302AF78E7CD56927C0AE123D_inline (const RuntimeMethod* method) 
{
	il2cpp_rgctx_method_init(method);
	CHECKED_LOCAL(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit);
	{
		CHECKED_LOCAL_INIT(EmptyArray_1_t6C301AAECD8237FCD6328D15A5BC0071D53D11A1_StaticInit,(il2cpp_rgctx_data(method->rgctx_data, 0)),il2cpp_codegen_runtime_class_init_inline);
		UnsafeList_1U5BU5D_tA7356AE11535E4817168FD5C6F3D906117E7E91B* L_0 = ((EmptyArray_1_t15EC9BF1140A58A19136B22B04EFD7559BBCC2D4_StaticFields*)il2cpp_codegen_static_fields_for(il2cpp_rgctx_data(method->rgctx_data, 0)))->___Value;
		return L_0;
	}
}
IL2CPP_MANAGED_FORCE_INLINE IL2CPP_METHOD_ATTR void Span_1__ctor_mBA868F06359701D9950DEB1B10F52F848E9FF6DA_fshared_inline (Span_1_tDEB40BEFA77B5E4BB49B058CD3050EEA4DD36C54* __this, Il2CppFullySharedGenericAny* ___0_ptr, int32_t ___1_length, const RuntimeMethod* method) 
{
	{
		Il2CppFullySharedGenericAny* L_0 = ___0_ptr;
		ByReference_1_t607C1F3BC28B0E21B969461CDB0720FB01A82141 L_1;
		memset((&L_1), 0, sizeof(L_1));
		il2cpp_codegen_by_reference_constructor((Il2CppByReference*)(&L_1), L_0);
		__this->____pointer = L_1;
		int32_t L_2 = ___1_length;
		__this->____length = L_2;
		return;
	}
}
