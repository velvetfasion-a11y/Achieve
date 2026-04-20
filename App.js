import React, { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Image,
  Modal,
  Platform,
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { NavigationContainer, DefaultTheme } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import * as ImagePicker from 'expo-image-picker';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { BlurView } from 'expo-blur';
import Svg, { Circle, Text as SvgText } from 'react-native-svg';
import Ionicons from '@expo/vector-icons/Ionicons';
import * as FileSystem from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import {
  Inter_400Regular,
  Inter_600SemiBold,
  Inter_700Bold,
  useFonts,
} from '@expo-google-fonts/inter';

const Tab = createBottomTabNavigator();

const STORAGE_KEYS = {
  accent: 'achieve.accent',
  habits: 'achieve.habits',
  notes: 'achieve.notes',
  photos: 'achieve.photos',
  settings: 'achieve.settings',
  history: 'achieve.history',
  coachChats: 'achieve.coachChats',
};

const DEFAULT_ACCENT = '#3F2A6B';
const COACH_MODES = ['Motivation', 'Routines', 'Energy'];
const TODAY_BACKGROUND = '#F8F4EB';

const DEFAULT_SETTINGS = {
  reminderFrequency: 'Daily',
  notificationStyle: 'Soft Chime',
  exportFormat: 'json',
  habitCategories: ['Mind', 'Body', 'Spirit', 'Creative'],
  defaultCoachMode: 'Motivation',
};

const COACH_OPENERS = {
  Motivation: 'Welcome to Motivation mode. One sincere day is enough.',
  Routines: 'Welcome to Routines mode. Let us build your dream-life structure.',
  Energy: 'Welcome to Energy mode. We protect your frequency first.',
};

const COACH_RESPONSES = {
  Motivation: [
    "You don't need a perfect day. You need an aligned one.",
    'A sincere step made with peace is stronger than ten forced steps.',
    "When you feel low, return to your Why. Purpose restores momentum.",
    "Progress is not loud. Sometimes it's one honest action in silence.",
  ],
  Routines: [
    'Keep your routine tiny and non-negotiable: one action per category.',
    'Anchor your hardest habit to a fixed trigger, not to motivation.',
    'Design for low-energy days so your system still works when tired.',
    'Measure consistency first, intensity second.',
  ],
  Energy: [
    'Protect your nervous system: breathe, hydrate, and simplify your next task.',
    'Your frequency drops when your actions and values are out of sync.',
    'Choose one thing that gives peace, then execute it fully.',
    'Do not chase output when your spirit asks for recalibration.',
  ],
};

const PRESET_COLORS = ['#3F2A6B', '#E8B923', '#C84B6F', '#10B981', '#1E3A8A'];

function getDateKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

function safeJsonParse(value, fallback) {
  if (!value) return fallback;
  try {
    return JSON.parse(value);
  } catch {
    return fallback;
  }
}

function calculateFrequency(habits) {
  if (!habits.length) return 0;
  const completed = habits.filter((habit) => habit.completed).length;
  return (completed / habits.length) * 100;
}

function calculateLifetimeFrequency(history) {
  const values = Object.values(history);
  if (!values.length) return 0;
  const total = values.reduce((sum, value) => sum + value, 0);
  return total / values.length;
}

function calculateStreak(history) {
  let streak = 0;
  const cursor = new Date();

  while (true) {
    const key = getDateKey(cursor);
    const dayFrequency = history[key];
    if (typeof dayFrequency === 'number' && dayFrequency > 0) {
      streak += 1;
      cursor.setDate(cursor.getDate() - 1);
      continue;
    }
    break;
  }

  return streak;
}

function normalizePhotos(stored) {
  if (!Array.isArray(stored)) return [];
  return stored.map((item, index) => {
    if (typeof item === 'string') {
      return {
        id: `${Date.now()}-${index}`,
        uri: item,
        createdAt: new Date().toISOString(),
      };
    }
    return item;
  });
}

function coachGreetingByMode() {
  const result = {};
  COACH_MODES.forEach((mode) => {
    result[mode] = [
      {
        id: `${mode}-welcome`,
        text: COACH_OPENERS[mode],
        isUser: false,
        createdAt: new Date().toISOString(),
      },
    ];
  });
  return result;
}

function buildSmartReminder(notes) {
  if (!notes.length) {
    return 'Your reminder for today: one sincere step with full presence.';
  }

  const last = notes[notes.length - 1];
  return `Daily reminder from your own words: "${last.text.slice(0, 90)}${last.text.length > 90 ? '...' : ''}"`;
}

function generateAffirmation(notes) {
  const seeds = [
    'I move with purpose, peace, and precision.',
    'I build my empire with sincere, aligned action.',
    'I choose consistency over pressure.',
    'My frequency rises every time I act from truth.',
  ];

  if (!notes.length) {
    return seeds[Math.floor(Math.random() * seeds.length)];
  }

  const source = notes[Math.floor(Math.random() * notes.length)].text.split(' ').slice(0, 4).join(' ');
  return `Today I honor "${source}" and turn it into action.`;
}

function buildCoachReply({ mode, input, notes, habits, todayFrequency }) {
  const modeReplies = COACH_RESPONSES[mode] || COACH_RESPONSES.Motivation;
  const randomReply = modeReplies[Math.floor(Math.random() * modeReplies.length)];
  const noteNudge = notes.length
    ? ` Reflection anchor: "${notes[notes.length - 1].text.slice(0, 42)}${notes[notes.length - 1].text.length > 42 ? '...' : ''}".`
    : '';
  const routineNudge =
    habits.length > 0
      ? ` Today your frequency is ${Math.round(todayFrequency)}%. Complete one more habit to raise it.`
      : ' Start with one tiny habit today and protect it.';
  const inputNudge = input.toLowerCase().includes('why')
    ? ' Return to your Why: who benefits when you stay aligned?'
    : '';

  return `${randomReply}${routineNudge}${noteNudge}${inputNudge}`;
}

function convertBundleToCsv(bundle) {
  const habitRows = bundle.habits
    .map((habit) => `${habit.id},"${habit.title.replace(/"/g, '""')}",${habit.category},${habit.completed}`)
    .join('\n');
  const noteRows = bundle.notes
    .map((note) => `${note.id},"${note.text.replace(/"/g, '""')}"`)
    .join('\n');
  const photoRows = bundle.photos.map((photo) => `${photo.id},"${photo.uri}"`).join('\n');

  return [
    'Section,Data',
    `ExportedAt,${bundle.exportedAt}`,
    '',
    'Habits',
    'id,title,category,completed',
    habitRows,
    '',
    'Notes',
    'id,text',
    noteRows,
    '',
    'Photos',
    'id,uri',
    photoRows,
  ].join('\n');
}

function RadialProgress({ percentage, accent }) {
  const radius = 70;
  const strokeWidth = 12;
  const circumference = 2 * Math.PI * radius;
  const progress = (Math.max(0, Math.min(percentage, 100)) / 100) * circumference;

  return (
    <Svg height="180" width="180" viewBox="0 0 160 160">
      <Circle cx="80" cy="80" r={radius} stroke="#ece4d7" strokeWidth={strokeWidth} fill="none" />
      <Circle
        cx="80"
        cy="80"
        r={radius}
        stroke={accent}
        strokeWidth={strokeWidth}
        fill="none"
        strokeDasharray={circumference}
        strokeDashoffset={circumference - progress}
        strokeLinecap="round"
        transform="rotate(-90 80 80)"
      />
      <SvgText x="80" y="84" textAnchor="middle" fill={accent} fontSize="30" fontWeight="700">
        {Math.round(percentage)}%
      </SvgText>
      <SvgText x="80" y="104" textAnchor="middle" fill="#6b7280" fontSize="11">
        TODAY
      </SvgText>
    </Svg>
  );
}

function AchieveScreen({ accent, habits, onAddHabit, onToggleHabit }) {
  const [newHabit, setNewHabit] = useState('');
  const [category, setCategory] = useState('Mind');
  const frequency = calculateFrequency(habits);

  const suggestions = [
    { title: 'Wake up at 6 AM', category: 'Body' },
    { title: 'Exercise 30 min', category: 'Body' },
    { title: 'Meditate 10 min', category: 'Mind' },
    { title: 'Pray', category: 'Spirit' },
    { title: 'Song production', category: 'Creative' },
    { title: 'Read 20 pages', category: 'Mind' },
  ];

  const addHabit = (title = newHabit.trim(), selectedCategory = category) => {
    if (!title) return;
    onAddHabit(title, selectedCategory);
    setNewHabit('');
  };

  return (
    <ScrollView style={styles.page} contentContainerStyle={styles.pageContent}>
      <View style={styles.centered}>
        <RadialProgress percentage={frequency} accent={accent} />
        <Text style={[styles.title, { color: accent }]}>Achieve</Text>
        <Text style={styles.subtitle}>One sincere day {`>`} 100% burnout</Text>
      </View>

      {habits.length === 0 ? (
        <View style={styles.emptyState}>
          <Text style={styles.emptyTitle}>Completely empty on day one.</Text>
          <Text style={styles.emptyText}>Add your first habit and make it 100% yours.</Text>
        </View>
      ) : (
        habits.map((habit) => (
          <TouchableOpacity key={habit.id} onPress={() => onToggleHabit(habit.id)} style={styles.habitRow}>
            <View style={[styles.checkbox, { backgroundColor: habit.completed ? accent : '#d1d5db' }]} />
            <View style={styles.habitTextWrap}>
              <Text style={[styles.habitText, habit.completed && styles.habitDone]}>{habit.title}</Text>
              <Text style={styles.habitCategory}>{habit.category || 'Mind'}</Text>
            </View>
          </TouchableOpacity>
        ))
      )}

      <View style={styles.inputContainer}>
        <TextInput
          style={styles.input}
          placeholder="New habit..."
          value={newHabit}
          onChangeText={setNewHabit}
          onSubmitEditing={() => addHabit()}
          returnKeyType="done"
        />
        <TouchableOpacity onPress={() => addHabit()} style={[styles.addButton, { backgroundColor: accent }]}>
          <Text style={styles.addButtonText}>+</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.categoryRow}>
        {['Mind', 'Body', 'Spirit', 'Creative'].map((item) => (
          <TouchableOpacity
            key={item}
            onPress={() => setCategory(item)}
            style={[
              styles.categoryChip,
              {
                borderColor: accent,
                backgroundColor: category === item ? accent : 'transparent',
              },
            ]}
          >
            <Text style={{ color: category === item ? '#fff' : accent, fontFamily: 'Inter_600SemiBold' }}>{item}</Text>
          </TouchableOpacity>
        ))}
      </View>

      <View style={styles.suggestionsContainer}>
        {suggestions.map((suggestion) => (
          <TouchableOpacity
            key={suggestion.title}
            onPress={() => addHabit(suggestion.title, suggestion.category)}
            style={[styles.suggestion, { borderColor: accent }]}
          >
            <Text style={{ color: accent, fontFamily: 'Inter_400Regular' }}>{suggestion.title}</Text>
          </TouchableOpacity>
        ))}
      </View>
    </ScrollView>
  );
}

function AICoachScreen({
  accent,
  notes,
  habits,
  todayFrequency,
  coachChats,
  setCoachChats,
  defaultCoachMode,
}) {
  const [mode, setMode] = useState(defaultCoachMode);
  const [input, setInput] = useState('');

  useEffect(() => {
    if (COACH_MODES.includes(defaultCoachMode)) {
      setMode(defaultCoachMode);
    }
  }, [defaultCoachMode]);

  const messages = coachChats[mode] || [];

  const sendMessage = () => {
    const trimmed = input.trim();
    if (!trimmed) return;

    const userMessage = {
      id: `${Date.now()}-u`,
      text: trimmed,
      isUser: true,
      createdAt: new Date().toISOString(),
    };

    setCoachChats((prev) => ({
      ...prev,
      [mode]: [...(prev[mode] || []), userMessage],
    }));
    setInput('');

    setTimeout(() => {
      const reply = buildCoachReply({
        mode,
        input: trimmed,
        notes,
        habits,
        todayFrequency,
      });
      const coachMessage = {
        id: `${Date.now()}-a`,
        text: reply,
        isUser: false,
        createdAt: new Date().toISOString(),
      };
      setCoachChats((prev) => ({
        ...prev,
        [mode]: [...(prev[mode] || []), coachMessage],
      }));
    }, 450);
  };

  return (
    <View style={styles.screen}>
      <Text style={[styles.title, { color: accent }]}>AI Coach</Text>
      <Text style={styles.subtitle}>Motivation • Routines • Energy</Text>

      <View style={styles.modeTabs}>
        {COACH_MODES.map((item) => (
          <TouchableOpacity
            key={item}
            onPress={() => setMode(item)}
            style={[
              styles.modeTab,
              {
                borderColor: accent,
                backgroundColor: mode === item ? accent : 'transparent',
              },
            ]}
          >
            <Text style={{ color: mode === item ? '#fff' : accent, fontFamily: 'Inter_600SemiBold' }}>{item}</Text>
          </TouchableOpacity>
        ))}
      </View>

      <ScrollView style={styles.chatContainer} contentContainerStyle={{ paddingBottom: 16 }}>
        {messages.map((message) => (
          <View
            key={message.id}
            style={[
              styles.message,
              message.isUser
                ? { alignSelf: 'flex-end', backgroundColor: accent }
                : { alignSelf: 'flex-start', backgroundColor: '#f2f2f5' },
            ]}
          >
            <Text style={{ color: message.isUser ? '#fff' : '#0f172a', fontFamily: 'Inter_400Regular' }}>
              {message.text}
            </Text>
          </View>
        ))}
      </ScrollView>

      <View style={styles.inputContainer}>
        <TextInput
          style={styles.input}
          placeholder="Ask anything..."
          value={input}
          onChangeText={setInput}
          onSubmitEditing={sendMessage}
          returnKeyType="send"
        />
        <TouchableOpacity onPress={sendMessage} style={[styles.sendButton, { backgroundColor: accent }]}>
          <Text style={{ color: '#fff', fontSize: 20, fontFamily: 'Inter_700Bold' }}>↑</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

function ProfileScreen({
  accent,
  setAccent,
  notes,
  setNotes,
  photos,
  setPhotos,
  settings,
  setSettings,
  habits,
  history,
  onExportData,
  onResetData,
}) {
  const [newNote, setNewNote] = useState('');
  const [customColor, setCustomColor] = useState(accent);
  const [selectedPhoto, setSelectedPhoto] = useState(null);

  const lifetimeFrequency = calculateLifetimeFrequency(history);
  const streak = calculateStreak(history);
  const reminder = buildSmartReminder(notes);
  const todayFrequency = calculateFrequency(habits);
  const totalCompletions = habits.filter((habit) => habit.completed).length;

  const leaderboard = useMemo(() => {
    const myScore = Math.round(lifetimeFrequency);
    return [
      { id: 1, name: 'Empire Builder #113', score: 96 },
      { id: 2, name: 'Empire Builder #742', score: 92 },
      { id: 3, name: 'You', score: myScore },
      { id: 4, name: 'Empire Builder #519', score: 84 },
    ].sort((a, b) => b.score - a.score);
  }, [lifetimeFrequency]);

  const updateSetting = (key, value) => {
    setSettings((prev) => ({ ...prev, [key]: value }));
  };

  const addNote = () => {
    const trimmed = newNote.trim();
    if (!trimmed) return;
    const next = [
      ...notes,
      {
        id: `${Date.now()}`,
        text: trimmed,
        createdAt: new Date().toISOString(),
      },
    ];
    setNotes(next);
    setNewNote('');
  };

  const addGeneratedAffirmation = () => {
    const text = generateAffirmation(notes);
    const next = [
      ...notes,
      {
        id: `${Date.now()}-ai`,
        text,
        createdAt: new Date().toISOString(),
      },
    ];
    setNotes(next);
  };

  const pickPhoto = async () => {
    if (Platform.OS !== 'web') {
      const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission required', 'We need access to your photos to journal moments.');
        return;
      }
    }

    const mediaTypes = ImagePicker.MediaTypeOptions?.Images || ['images'];
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes,
      allowsEditing: false,
      quality: 1,
    });

    if (result.canceled) return;
    const selected = result.assets[0];
    const next = [
      ...photos,
      {
        id: `${Date.now()}`,
        uri: selected.uri,
        width: selected.width,
        height: selected.height,
        createdAt: new Date().toISOString(),
      },
    ];
    setPhotos(next);
  };

  const applyCustomColor = () => {
    const value = customColor.trim();
    const validHex = /^#([0-9A-Fa-f]{6})$/.test(value);
    if (!validHex) {
      Alert.alert('Invalid color', 'Use a HEX color like #3F2A6B.');
      return;
    }
    setAccent(value);
  };

  return (
    <ScrollView style={styles.page} contentContainerStyle={styles.pageContent}>
      <View style={styles.profileHeader}>
        <BlurView intensity={90} tint="light" style={styles.avatar}>
          <Text style={{ fontSize: 56 }}>👤</Text>
        </BlurView>
        <Text style={styles.emailText}>velvetfasion@gmail.com</Text>
        <Text style={styles.dateText}>Account created: 26/01/2026</Text>
      </View>

      <Text style={[styles.sectionTitle, { color: accent }]}>Empire Dashboard</Text>
      <View style={styles.dashboard}>
        <View style={styles.stat}>
          <Text style={[styles.statValue, { color: accent }]}>{Math.round(lifetimeFrequency)}</Text>
          <Text style={styles.statLabel}>Lifetime Frequency</Text>
        </View>
        <View style={styles.stat}>
          <Text style={[styles.statValue, { color: accent }]}>{streak}</Text>
          <Text style={styles.statLabel}>Day Streak 🔥</Text>
        </View>
        <View style={styles.stat}>
          <Text style={[styles.statValue, { color: accent }]}>{Math.round(todayFrequency)}</Text>
          <Text style={styles.statLabel}>Today %</Text>
        </View>
      </View>

      <Text style={[styles.sectionTitle, { color: accent }]}>Accent Color</Text>
      <View style={styles.colorPicker}>
        {PRESET_COLORS.map((color) => (
          <TouchableOpacity
            key={color}
            onPress={() => {
              setAccent(color);
              setCustomColor(color);
            }}
            style={[
              styles.colorDot,
              { backgroundColor: color, borderColor: accent === color ? '#111827' : 'transparent' },
            ]}
          />
        ))}
      </View>
      <View style={styles.inputContainer}>
        <TextInput
          style={styles.input}
          value={customColor}
          onChangeText={setCustomColor}
          autoCapitalize="characters"
          placeholder="#3F2A6B"
        />
        <TouchableOpacity onPress={applyCustomColor} style={[styles.sendButton, { backgroundColor: accent }]}>
          <Ionicons name="checkmark" size={24} color="#fff" />
        </TouchableOpacity>
      </View>

      <Text style={[styles.sectionTitle, { color: accent }]}>Notes to Self</Text>
      <View style={styles.noteInputContainer}>
        <TextInput
          style={styles.noteInput}
          placeholder="Write your affirmation or reflection..."
          value={newNote}
          onChangeText={setNewNote}
          multiline
        />
        <TouchableOpacity onPress={addNote} style={[styles.smallAddButton, { backgroundColor: accent }]}>
          <Text style={{ color: '#fff', fontSize: 24, fontFamily: 'Inter_700Bold' }}>+</Text>
        </TouchableOpacity>
      </View>
      <TouchableOpacity onPress={addGeneratedAffirmation} style={[styles.button, { backgroundColor: accent }]}>
        <Text style={styles.buttonText}>Generate Empire Affirmation</Text>
      </TouchableOpacity>

      <View style={styles.reminderCard}>
        <Ionicons name="sparkles-outline" size={22} color={accent} />
        <Text style={styles.reminderText}>{reminder}</Text>
      </View>

      {notes.map((note) => (
        <View key={note.id} style={styles.noteCard}>
          <Text style={styles.noteText}>{note.text}</Text>
        </View>
      ))}

      <Text style={[styles.sectionTitle, { color: accent }]}>Journal Photos (full size)</Text>
      <TouchableOpacity onPress={pickPhoto} style={[styles.button, { backgroundColor: accent }]}>
        <Text style={styles.buttonText}>Add full-size photo</Text>
      </TouchableOpacity>
      <View style={styles.photoGrid}>
        {photos.map((photo) => (
          <TouchableOpacity key={photo.id} onPress={() => setSelectedPhoto(photo)} style={styles.photoCard}>
            <Image source={{ uri: photo.uri }} style={styles.photo} resizeMode="contain" />
          </TouchableOpacity>
        ))}
      </View>

      <Text style={[styles.sectionTitle, { color: accent }]}>Settings</Text>
      <Text style={styles.settingLabel}>Reminder Frequency</Text>
      <View style={styles.optionRow}>
        {['Off', 'Daily', 'Twice Daily', 'Custom'].map((item) => (
          <TouchableOpacity
            key={item}
            onPress={() => updateSetting('reminderFrequency', item)}
            style={[
              styles.settingChip,
              {
                borderColor: accent,
                backgroundColor: settings.reminderFrequency === item ? accent : 'transparent',
              },
            ]}
          >
            <Text
              style={{
                color: settings.reminderFrequency === item ? '#fff' : accent,
                fontFamily: 'Inter_600SemiBold',
              }}
            >
              {item}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      <Text style={styles.settingLabel}>Notification Style</Text>
      <View style={styles.optionRow}>
        {['Soft Chime', 'Silent', 'Vibration'].map((item) => (
          <TouchableOpacity
            key={item}
            onPress={() => updateSetting('notificationStyle', item)}
            style={[
              styles.settingChip,
              {
                borderColor: accent,
                backgroundColor: settings.notificationStyle === item ? accent : 'transparent',
              },
            ]}
          >
            <Text
              style={{
                color: settings.notificationStyle === item ? '#fff' : accent,
                fontFamily: 'Inter_600SemiBold',
              }}
            >
              {item}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      <Text style={styles.settingLabel}>Export Format</Text>
      <View style={styles.optionRow}>
        {['json', 'csv'].map((item) => (
          <TouchableOpacity
            key={item}
            onPress={() => updateSetting('exportFormat', item)}
            style={[
              styles.settingChip,
              {
                borderColor: accent,
                backgroundColor: settings.exportFormat === item ? accent : 'transparent',
              },
            ]}
          >
            <Text
              style={{
                color: settings.exportFormat === item ? '#fff' : accent,
                fontFamily: 'Inter_600SemiBold',
              }}
            >
              {item.toUpperCase()}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      <Text style={styles.settingLabel}>Default Coach Mode</Text>
      <View style={styles.optionRow}>
        {COACH_MODES.map((item) => (
          <TouchableOpacity
            key={item}
            onPress={() => updateSetting('defaultCoachMode', item)}
            style={[
              styles.settingChip,
              {
                borderColor: accent,
                backgroundColor: settings.defaultCoachMode === item ? accent : 'transparent',
              },
            ]}
          >
            <Text
              style={{
                color: settings.defaultCoachMode === item ? '#fff' : accent,
                fontFamily: 'Inter_600SemiBold',
              }}
            >
              {item}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      <TouchableOpacity onPress={() => onExportData(settings.exportFormat)} style={[styles.button, { backgroundColor: accent }]}>
        <Text style={styles.buttonText}>One-Tap Data Export</Text>
      </TouchableOpacity>

      <Text style={[styles.sectionTitle, { color: accent }]}>Anonymous Leaderboard</Text>
      <View style={styles.leaderboardCard}>
        {leaderboard.map((item, index) => (
          <View key={item.id} style={styles.leaderboardRow}>
            <Text style={styles.leaderboardText}>
              #{index + 1} {item.name}
            </Text>
            <Text style={[styles.leaderboardScore, { color: accent }]}>{item.score}</Text>
          </View>
        ))}
      </View>

      <TouchableOpacity onPress={onResetData} style={[styles.button, { backgroundColor: '#b91c1c' }]}>
        <Text style={styles.buttonText}>Sign Out & Delete Local Data</Text>
      </TouchableOpacity>

      <Modal visible={!!selectedPhoto} transparent animationType="fade">
        <View style={styles.photoModalBackdrop}>
          <TouchableOpacity style={styles.photoModalClose} onPress={() => setSelectedPhoto(null)}>
            <Ionicons name="close" size={30} color="#fff" />
          </TouchableOpacity>
          {selectedPhoto && <Image source={{ uri: selectedPhoto.uri }} style={styles.fullPhoto} resizeMode="contain" />}
        </View>
      </Modal>
    </ScrollView>
  );
}

export default function App() {
  const [accent, setAccent] = useState(DEFAULT_ACCENT);
  const [habits, setHabits] = useState([]);
  const [notes, setNotes] = useState([]);
  const [photos, setPhotos] = useState([]);
  const [settings, setSettings] = useState(DEFAULT_SETTINGS);
  const [history, setHistory] = useState({});
  const [coachChats, setCoachChats] = useState(coachGreetingByMode());
  const [hydrated, setHydrated] = useState(false);

  const [fontsLoaded] = useFonts({
    Inter_400Regular,
    Inter_600SemiBold,
    Inter_700Bold,
  });

  useEffect(() => {
    const load = async () => {
      try {
        const [
          storedAccent,
          storedHabits,
          storedNotes,
          storedPhotos,
          storedSettings,
          storedHistory,
          storedCoachChats,
        ] = await Promise.all([
          AsyncStorage.getItem(STORAGE_KEYS.accent),
          AsyncStorage.getItem(STORAGE_KEYS.habits),
          AsyncStorage.getItem(STORAGE_KEYS.notes),
          AsyncStorage.getItem(STORAGE_KEYS.photos),
          AsyncStorage.getItem(STORAGE_KEYS.settings),
          AsyncStorage.getItem(STORAGE_KEYS.history),
          AsyncStorage.getItem(STORAGE_KEYS.coachChats),
        ]);

        if (storedAccent) setAccent(storedAccent);
        setHabits(safeJsonParse(storedHabits, []));
        setNotes(safeJsonParse(storedNotes, []));
        setPhotos(normalizePhotos(safeJsonParse(storedPhotos, [])));
        setSettings({ ...DEFAULT_SETTINGS, ...safeJsonParse(storedSettings, {}) });
        setHistory(safeJsonParse(storedHistory, {}));
        setCoachChats({ ...coachGreetingByMode(), ...safeJsonParse(storedCoachChats, {}) });
      } catch (error) {
        console.warn('Failed to load local data', error);
      } finally {
        setHydrated(true);
      }
    };
    load();
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    AsyncStorage.setItem(STORAGE_KEYS.accent, accent).catch((error) =>
      console.warn('Failed to save accent', error)
    );
  }, [accent, hydrated]);

  useEffect(() => {
    if (!hydrated) return;
    AsyncStorage.setItem(STORAGE_KEYS.habits, JSON.stringify(habits)).catch((error) =>
      console.warn('Failed to save habits', error)
    );
  }, [habits, hydrated]);

  useEffect(() => {
    if (!hydrated) return;
    AsyncStorage.setItem(STORAGE_KEYS.notes, JSON.stringify(notes)).catch((error) =>
      console.warn('Failed to save notes', error)
    );
  }, [notes, hydrated]);

  useEffect(() => {
    if (!hydrated) return;
    AsyncStorage.setItem(STORAGE_KEYS.photos, JSON.stringify(photos)).catch((error) =>
      console.warn('Failed to save photos', error)
    );
  }, [photos, hydrated]);

  useEffect(() => {
    if (!hydrated) return;
    AsyncStorage.setItem(STORAGE_KEYS.settings, JSON.stringify(settings)).catch((error) =>
      console.warn('Failed to save settings', error)
    );
  }, [settings, hydrated]);

  useEffect(() => {
    if (!hydrated) return;
    AsyncStorage.setItem(STORAGE_KEYS.history, JSON.stringify(history)).catch((error) =>
      console.warn('Failed to save history', error)
    );
  }, [history, hydrated]);

  useEffect(() => {
    if (!hydrated) return;
    AsyncStorage.setItem(STORAGE_KEYS.coachChats, JSON.stringify(coachChats)).catch((error) =>
      console.warn('Failed to save coach chats', error)
    );
  }, [coachChats, hydrated]);

  const syncTodayHistory = (habitList) => {
    const key = getDateKey();
    const todayFrequency = calculateFrequency(habitList);
    setHistory((prev) => ({ ...prev, [key]: todayFrequency }));
  };

  const addHabit = (title, category) => {
    const trimmed = title.trim();
    if (!trimmed) return;
    const next = [
      ...habits,
      {
        id: `${Date.now()}`,
        title: trimmed,
        category,
        completed: false,
      },
    ];
    setHabits(next);
    syncTodayHistory(next);
  };

  const toggleHabit = (id) => {
    const next = habits.map((habit) =>
      habit.id === id ? { ...habit, completed: !habit.completed } : habit
    );
    setHabits(next);
    syncTodayHistory(next);
  };

  const exportData = async (format) => {
    const bundle = {
      exportedAt: new Date().toISOString(),
      habits,
      notes,
      photos,
      settings,
      history,
      coachChats,
    };

    try {
      const extension = format === 'csv' ? 'csv' : 'json';
      const filename = `achieve-export-${Date.now()}.${extension}`;
      const directory = FileSystem.cacheDirectory || FileSystem.documentDirectory;
      const uri = `${directory}${filename}`;
      const payload = format === 'csv' ? convertBundleToCsv(bundle) : JSON.stringify(bundle, null, 2);

      await FileSystem.writeAsStringAsync(uri, payload);
      const canShare = await Sharing.isAvailableAsync();

      if (canShare) {
        await Sharing.shareAsync(uri, {
          dialogTitle: 'Export Achieve data',
          mimeType: format === 'csv' ? 'text/csv' : 'application/json',
          UTI: format === 'csv' ? 'public.comma-separated-values-text' : 'public.json',
        });
      } else {
        Alert.alert('Export ready', `Data saved at ${uri}`);
      }
    } catch (error) {
      Alert.alert('Export failed', 'Unable to export data right now.');
      console.warn('Export failed', error);
    }
  };

  const resetAllData = () => {
    Alert.alert(
      'Delete everything?',
      'This removes all local habits, notes, photos, chats, and settings.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await AsyncStorage.multiRemove(Object.values(STORAGE_KEYS));
              setAccent(DEFAULT_ACCENT);
              setHabits([]);
              setNotes([]);
              setPhotos([]);
              setSettings(DEFAULT_SETTINGS);
              setHistory({});
              setCoachChats(coachGreetingByMode());
              Alert.alert('Completed', 'All local data was deleted.');
            } catch (error) {
              Alert.alert('Error', 'Could not clear local data.');
              console.warn('Failed to clear data', error);
            }
          },
        },
      ]
    );
  };

  const theme = {
    ...DefaultTheme,
    colors: {
      ...DefaultTheme.colors,
      background: TODAY_BACKGROUND,
    },
  };

  if (!fontsLoaded || !hydrated) {
    return (
      <SafeAreaView style={styles.loading}>
        <StatusBar barStyle="dark-content" />
        <Text style={styles.loadingText}>Loading Achieve...</Text>
      </SafeAreaView>
    );
  }

  return (
    <NavigationContainer theme={theme}>
      <StatusBar barStyle="dark-content" />
      <Tab.Navigator
        screenOptions={({ route }) => ({
          headerShown: false,
          tabBarActiveTintColor: accent,
          tabBarInactiveTintColor: '#64748b',
          tabBarStyle: styles.tabBar,
          tabBarIcon: ({ color, size }) => {
            const icons = {
              Achieve: 'radio-button-on-outline',
              'AI Coach': 'sparkles-outline',
              Profile: 'person-circle-outline',
            };
            const iconName = icons[route.name] || 'ellipse-outline';
            return <Ionicons name={iconName} size={size} color={color} />;
          },
        })}
      >
        <Tab.Screen name="Achieve">
          {() => <AchieveScreen accent={accent} habits={habits} onAddHabit={addHabit} onToggleHabit={toggleHabit} />}
        </Tab.Screen>
        <Tab.Screen name="AI Coach">
          {() => (
            <AICoachScreen
              accent={accent}
              notes={notes}
              habits={habits}
              todayFrequency={calculateFrequency(habits)}
              coachChats={coachChats}
              setCoachChats={setCoachChats}
              defaultCoachMode={settings.defaultCoachMode}
            />
          )}
        </Tab.Screen>
        <Tab.Screen name="Profile">
          {() => (
            <ProfileScreen
              accent={accent}
              setAccent={setAccent}
              notes={notes}
              setNotes={setNotes}
              photos={photos}
              setPhotos={setPhotos}
              settings={settings}
              setSettings={setSettings}
              habits={habits}
              history={history}
              onExportData={exportData}
              onResetData={resetAllData}
            />
          )}
        </Tab.Screen>
      </Tab.Navigator>
    </NavigationContainer>
  );
}

const styles = StyleSheet.create({
  loading: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: TODAY_BACKGROUND,
  },
  loadingText: {
    fontFamily: 'Inter_600SemiBold',
    fontSize: 18,
    color: '#1f2937',
  },
  tabBar: {
    backgroundColor: '#fff',
    borderTopColor: '#e5e7eb',
    height: 64,
    paddingBottom: 8,
    paddingTop: 6,
  },
  screen: {
    flex: 1,
    backgroundColor: TODAY_BACKGROUND,
    padding: 20,
    paddingTop: 56,
  },
  page: {
    flex: 1,
    backgroundColor: TODAY_BACKGROUND,
  },
  pageContent: {
    padding: 20,
    paddingBottom: 40,
  },
  centered: {
    alignItems: 'center',
  },
  title: {
    fontSize: 31,
    fontFamily: 'Inter_700Bold',
    marginTop: 2,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 14,
    color: '#6b7280',
    textAlign: 'center',
    marginBottom: 14,
    marginTop: 2,
    fontFamily: 'Inter_400Regular',
  },
  emptyState: {
    backgroundColor: '#fff',
    borderRadius: 18,
    padding: 20,
    marginVertical: 14,
  },
  emptyTitle: {
    fontSize: 20,
    fontFamily: 'Inter_700Bold',
    marginBottom: 8,
    color: '#111827',
  },
  emptyText: {
    fontSize: 16,
    color: '#6b7280',
    fontFamily: 'Inter_400Regular',
  },
  habitRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 16,
    marginBottom: 12,
  },
  habitTextWrap: {
    flex: 1,
  },
  checkbox: {
    width: 28,
    height: 28,
    borderRadius: 14,
    marginRight: 14,
  },
  habitText: {
    fontSize: 17,
    color: '#111827',
    fontFamily: 'Inter_600SemiBold',
  },
  habitDone: {
    textDecorationLine: 'line-through',
    color: '#6b7280',
  },
  habitCategory: {
    color: '#6b7280',
    marginTop: 4,
    fontSize: 12,
    fontFamily: 'Inter_400Regular',
  },
  inputContainer: {
    flexDirection: 'row',
    width: '100%',
    marginVertical: 10,
  },
  input: {
    flex: 1,
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 16,
    fontSize: 17,
    marginRight: 12,
    fontFamily: 'Inter_400Regular',
  },
  addButton: {
    width: 56,
    height: 56,
    borderRadius: 28,
    justifyContent: 'center',
    alignItems: 'center',
  },
  addButtonText: {
    fontSize: 32,
    color: '#fff',
    lineHeight: 34,
    fontFamily: 'Inter_700Bold',
  },
  categoryRow: {
    width: '100%',
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 8,
  },
  categoryChip: {
    borderWidth: 1,
    paddingVertical: 7,
    paddingHorizontal: 14,
    borderRadius: 999,
    marginRight: 8,
    marginBottom: 8,
  },
  suggestionsContainer: {
    width: '100%',
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: 8,
  },
  suggestion: {
    paddingVertical: 8,
    paddingHorizontal: 14,
    borderWidth: 1,
    borderRadius: 12,
    marginRight: 8,
    marginBottom: 8,
    backgroundColor: '#fff',
  },
  modeTabs: {
    flexDirection: 'row',
    marginBottom: 12,
  },
  modeTab: {
    borderWidth: 1,
    borderRadius: 999,
    paddingVertical: 7,
    paddingHorizontal: 14,
    marginRight: 8,
  },
  chatContainer: {
    flex: 1,
    marginBottom: 12,
  },
  message: {
    padding: 14,
    borderRadius: 20,
    marginVertical: 6,
    maxWidth: '85%',
  },
  sendButton: {
    width: 56,
    height: 56,
    borderRadius: 28,
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: 12,
  },
  profileHeader: {
    alignItems: 'center',
    marginVertical: 16,
  },
  avatar: {
    width: 120,
    height: 120,
    borderRadius: 60,
    justifyContent: 'center',
    alignItems: 'center',
    overflow: 'hidden',
  },
  emailText: {
    marginTop: 10,
    fontSize: 18,
    fontFamily: 'Inter_600SemiBold',
    color: '#111827',
  },
  dateText: {
    marginTop: 2,
    fontSize: 14,
    color: '#6b7280',
    fontFamily: 'Inter_400Regular',
  },
  sectionTitle: {
    fontSize: 23,
    marginBottom: 10,
    marginTop: 14,
    fontFamily: 'Inter_700Bold',
  },
  dashboard: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: '#fff',
    padding: 18,
    borderRadius: 20,
    marginBottom: 10,
  },
  stat: {
    alignItems: 'center',
    flex: 1,
  },
  statValue: {
    fontSize: 34,
    fontFamily: 'Inter_700Bold',
  },
  statLabel: {
    marginTop: 4,
    fontSize: 12,
    color: '#6b7280',
    textAlign: 'center',
    fontFamily: 'Inter_400Regular',
  },
  noteInputContainer: {
    flexDirection: 'row',
    marginBottom: 12,
  },
  noteInput: {
    flex: 1,
    backgroundColor: '#fff',
    padding: 14,
    borderRadius: 16,
    fontSize: 16,
    minHeight: 84,
    textAlignVertical: 'top',
    marginRight: 12,
    fontFamily: 'Inter_400Regular',
  },
  smallAddButton: {
    width: 56,
    height: 56,
    borderRadius: 28,
    justifyContent: 'center',
    alignItems: 'center',
  },
  reminderCard: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 14,
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 10,
  },
  reminderText: {
    flex: 1,
    marginLeft: 10,
    color: '#374151',
    lineHeight: 21,
    fontFamily: 'Inter_400Regular',
  },
  noteCard: {
    backgroundColor: '#fff',
    padding: 14,
    borderRadius: 16,
    marginBottom: 8,
  },
  noteText: {
    color: '#111827',
    fontFamily: 'Inter_400Regular',
  },
  button: {
    padding: 15,
    borderRadius: 16,
    alignItems: 'center',
    marginVertical: 6,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontFamily: 'Inter_700Bold',
  },
  colorPicker: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 2,
  },
  colorDot: {
    width: 46,
    height: 46,
    borderRadius: 24,
    marginRight: 10,
    marginBottom: 10,
    borderWidth: 3,
  },
  photoGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  photoCard: {
    width: '48%',
    borderRadius: 14,
    backgroundColor: '#fff',
    padding: 6,
    marginBottom: 12,
  },
  photo: {
    width: '100%',
    height: 180,
    borderRadius: 12,
    backgroundColor: '#f3f4f6',
  },
  settingLabel: {
    color: '#374151',
    marginTop: 10,
    marginBottom: 8,
    fontFamily: 'Inter_600SemiBold',
  },
  optionRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 4,
  },
  settingChip: {
    borderWidth: 1,
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 8,
    marginRight: 8,
    marginBottom: 8,
    backgroundColor: '#fff',
  },
  leaderboardCard: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 12,
    marginBottom: 10,
  },
  leaderboardRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  leaderboardText: {
    color: '#374151',
    fontFamily: 'Inter_400Regular',
  },
  leaderboardScore: {
    fontFamily: 'Inter_700Bold',
  },
  photoModalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.95)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },
  fullPhoto: {
    width: '100%',
    height: '85%',
  },
  photoModalClose: {
    position: 'absolute',
    right: 18,
    top: 52,
    zIndex: 2,
  },
});
