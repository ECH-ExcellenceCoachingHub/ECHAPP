import 'package:flutter/widgets.dart';

/// Kinyarwanda for the school module (students, parents, teachers, school admins).
///
/// Use [T] instead of `Text` for fixed strings, or `trSchool(context, '...')`
/// for strings passed as properties. Text in the dictionary is translated when
/// the app language is Kinyarwanda; anything else stays in English.
/// Patterns with {placeholders} cover sentences with names/numbers; captured
/// parts are translated too ("Due {x}" + "today" → "Igihe ntarengwa: uyu munsi").
///
/// Translations should be reviewed by a native speaker before wide release.

bool isKinyarwanda(BuildContext context) {
  try {
    return Localizations.localeOf(context).languageCode == 'rw';
  } catch (_) {
    return false;
  }
}

String trSchool(BuildContext context, String en) => isKinyarwanda(context) ? _rw(en) : en;

/// A `Text` that translates its string into Kinyarwanda when the app is in Kinyarwanda.
class T extends StatelessWidget {
  const T(this.text, {super.key, this.style, this.textAlign, this.maxLines, this.overflow, this.softWrap});
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) => Text(trSchool(context, text), style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow, softWrap: softWrap);
}

String _rw(String en, [int depth = 0]) {
  final s = en.trim();
  if (s.isEmpty) return en;
  final exact = _exact[s];
  if (exact != null) return exact;
  if (depth > 2) return en;
  for (final p in _compiled) {
    final m = p.regex.firstMatch(s);
    if (m == null) continue;
    var out = p.rw;
    for (var i = 0; i < p.names.length; i++) {
      out = out.replaceAll('{${p.names[i]}}', _rw(m.group(i + 1) ?? '', depth + 1));
    }
    return out;
  }
  return en;
}

class _Pattern {
  _Pattern(this.regex, this.names, this.rw);
  final RegExp regex;
  final List<String> names;
  final String rw;
}

final List<_Pattern> _compiled = [
  for (final e in _patterns.entries) _compile(e.key, e.value),
];

_Pattern _compile(String en, String rw) {
  final names = <String>[];
  final buf = StringBuffer('^');
  final re = RegExp(r'\{(\w+)\}');
  var last = 0;
  for (final m in re.allMatches(en)) {
    buf.write(RegExp.escape(en.substring(last, m.start)));
    buf.write('(.+?)');
    names.add(m.group(1)!);
    last = m.end;
  }
  buf.write(RegExp.escape(en.substring(last)));
  buf.write(r'$');
  return _Pattern(RegExp(buf.toString()), names, rw);
}

const Map<String, String> _patterns = {
  'Hello, {name}': 'Muraho, {name}',
  'Due {x}': 'Igihe ntarengwa: {x}',
  'Due {x} ({y})': 'Igihe ntarengwa: {x} ({y})',
  'in {n} days': 'mu minsi {n}',
  '{n} days ago': 'hashize iminsi {n}',
  '{n} students': 'abanyeshuri {n}',
  '{n} student': 'umunyeshuri {n}',
  '{n} to do': '{n} byo gukora',
  '{n} overdue': '{n} byarengeje igihe',
  '{n} missed': '{n} bitakozwe',
  '{n} handed in': '{n} byoherejwe',
  '{n} new messages': 'ubutumwa bushya {n}',
  '{n} new message': 'ubutumwa bushya {n}',
  'Average {n}': 'Impuzandengo {n}',
  'Your mark: {x}': 'Amanota yawe: {x}',
  'You handed in {x}': 'Wohereje {x}',
  'Taught {x}': 'Ryigishijwe {x}',
  'Class teacher: {x}': 'Umwarimu w\'ishuri: {x}',
  'Class teacher of {x}': 'Umwarimu w\'ishuri rya {x}',
  'Are you {name}?': 'Ni wowe {name}?',
  '{x} lessons taught': 'amasomo {x} yigishijwe',
  'last {x}': 'irya nyuma {x}',
  'Last lesson {x}': 'Isomo rya nyuma {x}',
  'Signed in with this code today ({n})': 'Binjiye bakoresheje iyi kode uyu munsi ({n})',
  'Class code · {x}': 'Kode y\'ishuri · {x}',
  'School code · {x}': 'Kode y\'ikigo · {x}',
  'Students of {x} sign in with': 'Abanyeshuri ba {x} binjira bakoresheje',
  '{n} min left': 'hasigaye iminota {n}',
  '{n} s left': 'hasigaye amasegonda {n}',
  'Homework · {x}': 'Umukoro · {x}',
  'Send to {x}': 'Ohereza kuri {x}',
  'Start {x}': 'Tangira {x}',
  'New PIN for {x}?': 'PIN nshya ya {x}?',
  'New sign-in for {x}': 'Kwinjira gushya kwa {x}',
  'Print login cards for {x}?': 'Gucapa amakarita yo kwinjira ya {x}?',
  'Remove {x}?': 'Gukuraho {x}?',
  '{x} is registered': '{x} yanditswe',
};

const Map<String, String> _exact = {
  // ── General ──
  'Cancel': 'Reka', 'Save': 'Bika', 'Done': 'Ndangije', 'OK': 'Sawa', 'Yes': 'Yego', 'No': 'Oya', 'Close': 'Funga',
  'Open': 'Fungura', 'Add': 'Ongeraho', 'Edit details': 'Hindura amakuru', 'Remove': 'Kuraho', 'Delete': 'Siba',
  'Refresh': 'Vugurura', 'Try again': 'Ongera ugerageze', 'Could not load': 'Ntibyashobotse gufungura', 'Copy': 'Koporora',
  'Copy all': 'Koporora byose', 'Copied': 'Byakoporowe', 'Search': 'Shakisha', 'All': 'Byose', 'None': 'Nta na kimwe',
  'Back': 'Subira inyuma', 'Next': 'Ibikurikira', 'Start': 'Tangira', 'Sign out': 'Sohoka', 'Notifications': 'Imenyesha',
  'today': 'uyu munsi', 'tomorrow': 'ejo', 'yesterday': 'ejo hashize', 'never': 'nta na rimwe', 'Nobody yet.': 'Nta muntu urinjira.',
  // ── Roles and things ──
  'Student': 'Umunyeshuri', 'Students': 'Abanyeshuri', 'Young pupil': 'Umwana muto', 'Parent': 'Umubyeyi', 'Parents': 'Ababyeyi',
  'Teacher': 'Mwarimu', 'Teachers': 'Abarimu', 'Class': 'Ishuri', 'Classes': 'Amashuri', 'School': 'Ikigo', 'Subject': 'Isomo',
  'Subjects': 'Amasomo', 'Homework': 'Umukoro', 'Quiz': 'Isuzuma rito', 'Exam': 'Ikizamini',
  // ── Sign-in ──
  'Sign in': 'Injira', 'Sign in with your school': 'Injira ukoresheje ikigo cyawe', 'School code & PIN': 'Kode y\'ikigo na PIN',
  'Student code': 'Kode y\'umunyeshuri', 'PIN': 'PIN', 'Phone number': 'Nimero ya telefone', 'Class code': 'Kode y\'ishuri',
  'Use the student code and PIN your school gave you.': 'Koresha kode y\'umunyeshuri na PIN wahawe n\'ikigo.',
  'Type the class code your teacher shows, then tap your name.': 'Andika kode y\'ishuri mwarimu akwereka, hanyuma ukande izina ryawe.',
  'Use the phone number you gave the school and your PIN.': 'Koresha nimero ya telefone wahaye ikigo na PIN yawe.',
  'My teacher gave a class code': 'Mwarimu yampaye kode y\'ishuri',
  'Open my class': 'Fungura ishuri ryanjye', 'Tap your name': 'Kanda izina ryawe',
  'Wrong class? Enter the code again': 'Si ishuri ryawe? Ongera wandike kode',
  'Only tap your own name. Your teacher can see who signed in.': 'Kanda izina ryawe gusa. Mwarimu abona abinjiye.',
  'Yes, it is me': 'Yego, ni njye',
  'Forgot your PIN? Ask the school office for a new one.': 'Wibagiwe PIN? Saba ubunyamabanga bw\'ikigo indi nshya.',
  'Forgot your PIN? Ask your class teacher. Only one device can use a student account at a time.':
      'Wibagiwe PIN? Baza mwarimu w\'ishuri ryawe. Konti y\'umunyeshuri ikoreshwa ku gikoresho kimwe gusa icyarimwe.',
  'Your school asks for the class code. Ask your teacher for the code shown in class.':
      'Ikigo cyawe gisaba kode y\'ishuri. Saba mwarimu kode yerekanwa mu ishuri.',
  'Change my PIN': 'Hindura PIN yanjye', 'Current PIN': 'PIN usanzwe ukoresha', 'New PIN': 'PIN nshya', 'New PIN again': 'Ongera wandike PIN nshya',
  'PIN changed': 'PIN yahinduwe', 'Change PIN': 'Hindura PIN', 'PINs do not match': 'PIN ntizihura',
  'The PIN has 6 digits': 'PIN igizwe n\'imibare 6',
  '6 digits shown by your teacher': 'Imibare 6 mwarimu akwereka', 'Enter your phone number': 'Andika nimero ya telefone yawe',
  'Enter your student code': "Andika kode yawe y'umunyeshuri", '6 digits': 'Imibare 6', 'Password': 'Ijambobanga',
  '6 digits, not all the same or in a row': 'Imibare 6, itari imwe yose cyangwa ikurikiranye',
  // ── Student / parent home ──
  'My school': 'Ikigo cyanjye', 'My children': 'Abana banjye', 'Child': 'Umwana', 'Academic year': 'Umwaka w\'amashuri',
  'Class teacher': 'Umwarimu w\'ishuri', 'Not in a class yet': 'Ntaraba mu ishuri', 'No teacher yet': 'Nta mwarimu uragenwa',
  'To do': 'Ibyo gukora', 'Overdue': 'Byarengeje igihe', 'Missed': 'Bitakozwe', 'Handed in': 'Byoherejwe',
  'Homework & work to do': 'Umukoro n\'imirimo yo gukora', 'Homework to do': 'Umukoro wo gukora',
  'Tap one to read it and hand it in.': 'Kanda kuri umwe kugira ngo uwusome kandi uwohereze.',
  'Nothing due. Well done!': 'Nta kintu kigutegereje. Wakoze neza!',
  'Class groups': 'Amatsinda y\'ishuri', 'Discuss with your teachers and classmates.': 'Ganira n\'abarimu na bagenzi bawe.',
  'No groups yet. Your teachers can add you to one.': 'Nta tsinda rirabaho. Abarimu bashobora kugushyira mu itsinda.',
  'Was this lesson taught?': 'Iri somo ryarigishijwe?', 'Your answer is private and helps the school.': 'Igisubizo cyawe ni ibanga kandi gifasha ikigo.',
  'My subjects': 'Amasomo yanjye', 'Recent work and marks': 'Imirimo iheruka n\'amanota',
  'All ECH courses are free for you': 'Amasomo yose ya ECH ni ubuntu kuri wowe', 'Your school pays for them this term.': 'Ikigo cyawe ni cyo kiyishyura iki gihembwe.',
  'Browse': 'Reba', 'ECH courses': 'Amasomo ya ECH', 'No children linked': 'Nta mwana uhujwe na konti yawe',
  'Late — hand in now': 'Byatinze — ohereza ubu',
  // ── Homework (student) ──
  'Your work': 'Umukoro wawe', 'Your answer': 'Igisubizo cyawe', 'Comment (optional)': 'Igitekerezo (si ngombwa)',
  'Add a photo of your work': 'Ongeraho ifoto y\'umukoro wawe', 'Add another photo': 'Ongeraho indi foto',
  'Hand in': 'Ohereza', 'Hand in late': 'Ohereza utinze', 'Hand in again (replaces)': 'Ongera wohereze (bisimbura ibya mbere)',
  'Handed in late': 'Byoherejwe bitinze', 'This homework is closed.': 'Uyu mukoro wafunzwe.',
  'This is done on eexams': 'Ibi bikorerwa kuri eexams', 'Open on eexams': 'Fungura kuri eexams',
  'No comment from the teacher.': 'Mwarimu nta gitekerezo yatanze.',
  'Take a photo': 'Fata ifoto', 'Choose from gallery': 'Hitamo mu mafoto',
  // ── Groups ──
  'New group': 'Itsinda rishya', 'New class group': 'Itsinda rishya ry\'ishuri', 'Create group': 'Kora itsinda',
  'Group name': 'Izina ry\'itsinda', 'Members': 'Abanyamuryango', 'Whole class': 'Ishuri ryose', 'Choose students': 'Hitamo abanyeshuri',
  'Announcements only': 'Amatangazo gusa', 'Only teachers can post; students read and get notified.': 'Abarimu bonyine ni bo bandika; abanyeshuri barasoma kandi bakamenyeshwa.',
  'Only teachers can post in this group.': 'Abarimu bonyine ni bo bandika muri iri tsinda.',
  'Write a message': 'Andika ubutumwa', 'No messages yet': 'Nta butumwa buraba', 'Start the discussion.': 'Tangiza ikiganiro.',
  'Your teacher will post here.': 'Mwarimu azandika hano.', 'Reply': 'Subiza', 'Pin for everyone': 'Shyira hejuru ku bose', 'Unpin': 'Kuraho hejuru',
  'Message deleted': 'Ubutumwa bwasibwe', 'Older messages': 'Ubutumwa bwa kera', 'Close group': 'Funga itsinda',
  'Add a teacher to moderate': 'Ongeramo undi mwarimu ugenzura',
  // ── Class code screen ──
  'Sign-in code': 'Kode yo kwinjira', 'this code, then tap their name': 'iyi kode, hanyuma bakande izina ryabo',
  'student code + PIN + this code': 'kode y\'umunyeshuri + PIN + iyi kode',
  'Any student of the school signs in with': 'Umunyeshuri wese w\'ikigo yinjira akoresheje',
  'Check that everyone here is really in the room.': 'Genzura ko buri wese uri hano ari mu ishuri koko.',
  'changing…': 'irahinduka…',
  // ── Teacher ──
  'My classes': 'Amashuri yanjye', 'Lab code': 'Kode ya laboratwari', 'Groups': 'Amatsinda',
  'Mark lessons you taught, give homework, mark hand-ins.': 'Andika amasomo wigishije, tanga umukoro, ukosore ibyoherejwe.',
  'Lessons taught': 'Amasomo yigishijwe', 'Mark a lesson': 'Andika isomo', 'Mark taught': 'Byigishijwe', 'Give homework': 'Tanga umukoro',
  'Marked as taught': 'Ryanditswe ko ryigishijwe', 'Undo': 'Kuraho', 'Class list': 'Urutonde rw\'ishuri',
  'Register student': 'Andika umunyeshuri', 'Add existing student': 'Ongeramo umunyeshuri usanzwe', 'Import a list': 'Injiza urutonde',
  'Print login cards': 'Capa amakarita yo kwinjira', 'Create cards': 'Kora amakarita',
  'Not handed in': 'Ntibyoherejwe', 'To mark': 'Byo gukosora', 'Save mark': 'Bika amanota', 'Feedback for the student': 'Inama ku munyeshuri',
  // ── School admin navigation ──
  'Overview': 'Incamake', 'Teachers & staff': 'Abarimu n\'abakozi', 'Lesson progress': 'Aho amasomo agereye', 'Results': 'Amanota',
  'Student sign-in': 'Kwinjira kw\'abanyeshuri', 'Sign-in activity': 'Abinjiye', 'Terms & billing': 'Ibihembwe n\'ubwishyu',
  'School profile': 'Umwirondoro w\'ikigo', 'Get your school ready': 'Tegura ikigo cyawe', 'Needs attention': 'Bikeneye kwitabwaho',
  'This week': 'Iki cyumweru', 'Year-end promotion': 'Kwimuka mu mwaka mushya', 'Add classes': 'Ongeraho amashuri',
  'Add teacher': 'Ongeraho mwarimu', 'Add school admin': 'Ongeraho umuyobozi', 'Flagged lessons': 'Amasomo akemangwa',
  'Lessons marked taught': 'Amasomo yanditswe ko yigishijwe', 'Homework given': 'Imikoro yatanzwe', 'Hand-ins': 'Ibyoherejwe',
  'Save rules': 'Bika amategeko', 'Where can students sign in?': 'Abanyeshuri binjirira he?', 'Anywhere': 'Ahantu hose',
  'School day': 'Umunsi w\'ishuri', 'School internet': 'Interineti y\'ikigo',
};
