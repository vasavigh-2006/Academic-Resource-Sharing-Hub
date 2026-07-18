import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';

class AIService {
  // Groq API — key stored in lib/config/secrets.dart (gitignored)
  static final String _groqApiKey = AppSecrets.groqApiKey;
  static const String _groqModel = 'llama-3.3-70b-versatile';
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

  AIService();

  // ── Lecture Notes ──────────────────────────────────────────────────────────
  Future<String> generateLectureNotes({
    required String topic,
    required String branch,
    required String semester,
  }) async {
    final prompt = '''You are an expert $branch engineering professor.
Generate detailed lecture notes for Semester $semester on: "$topic".
Use clean Markdown with these sections:
1. # Lecture Title: $topic
2. ## Overview & Learning Objectives
3. ## Key Technical Concepts
4. ## Code Example or Diagram
5. ## Exam Practice Questions (3 questions with guidance)''';

    final aiResponse = await _callGroq(prompt);
    if (aiResponse != null && aiResponse.isNotEmpty) return aiResponse;

    return _buildLectureNotes(topic, branch, semester);
  }

  // ── Universal Lecture Notes Builder ────────────────────────────────────────
  String _buildLectureNotes(String topic, String branch, String semester) {
    final t = topic.toLowerCase();

    // Detect topic domain and pick matching language + concepts
    final bool isDB = _anyIn(t, ['database', 'dbms', 'sql', 'query', 'table', 'relation', 'normalization', 'transaction', 'index']);
    final bool isOS = _anyIn(t, ['operating system', 'process', 'thread', 'deadlock', 'scheduling', 'memory', 'paging', 'semaphore', 'mutex', 'file system']);
    final bool isNetwork = _anyIn(t, ['network', 'tcp', 'ip', 'http', 'dns', 'protocol', 'routing', 'socket', 'bandwidth', 'osi', 'packet']);
    final bool isML = _anyIn(t, ['machine learning', 'neural', 'deep learning', 'ai ', 'regression', 'classification', 'cluster', 'training', 'model']);
    final bool isAlgo = _anyIn(t, ['sort', 'search', 'algorithm', 'graph', 'tree', 'recursion', 'dynamic programming', 'greedy', 'backtrack', 'bfs', 'dfs', 'dijkstra']);
    final bool isOOP = _anyIn(t, ['oops', 'oop', 'class', 'object', 'inheritance', 'polymorphism', 'encapsulation', 'abstraction', 'interface']);
    final bool isMath = _anyIn(t, ['calculus', 'matrix', 'probability', 'statistics', 'linear algebra', 'differential', 'integral', 'fourier', 'laplace']);

    final String lang = isDB ? 'sql' : isOS ? 'c' : isML ? 'python' : 'dart';
    final String concepts = _domainConcepts(topic, isDB, isOS, isNetwork, isML, isAlgo, isOOP, isMath);
    final String codeBlock = _domainCode(topic, lang, isDB, isOS, isML, isAlgo, isOOP);
    final String questions = _domainQuestions(topic, isDB, isOS, isNetwork, isML, isAlgo);

    return '''# Lecture: Comprehensive Guide to $topic

## Overview & Learning Objectives
Designed for **Semester $semester — $branch Engineering**.
This lecture provides an in-depth study of **$topic**, covering its theoretical foundations, architectural mechanics, and practical implementations.

### Key Outcomes:
* Define and explain the core principles of $topic
* Identify real-world applications and industry use cases
* Implement solutions and evaluate complexity trade-offs

---

$concepts

---

## Code Example (${lang.toUpperCase()})
$codeBlock

---

## Exam Practice Questions
$questions
''';
  }

  bool _anyIn(String t, List<String> keys) => keys.any((k) => t.contains(k));

  String _domainConcepts(String topic, bool isDB, bool isOS, bool isNetwork,
      bool isML, bool isAlgo, bool isOOP, bool isMath) {
    if (isDB) return '''## Key Technical Concepts

1. **Core Definition:**
   $topic refers to the systematic management of structured data using a Database Management System (DBMS), ensuring data integrity, consistency, and efficient access.

2. **Structural Mechanics:**
   - **Schema Design:** Defines tables, attributes, primary keys, and foreign key relationships
   - **Query Execution:** SQL queries are parsed → optimised → executed against the storage engine
   - **ACID Properties:** Atomicity, Consistency, Isolation, Durability — guarantee transaction reliability

3. **Performance Metrics:**
   - Indexed queries: O(log n) using B-Tree indexing
   - Full table scan: O(n) — avoided by proper indexing
   - Join complexity: O(n·m) worst case; optimised by query planner''';

    if (isOS) return '''## Key Technical Concepts

1. **Core Definition:**
   $topic is a fundamental Operating System concept responsible for managing system resources, processes, and hardware interactions in a safe, efficient manner.

2. **Structural Mechanics:**
   - **Kernel Mode vs User Mode:** OS separates privileged operations from user-space execution
   - **System Calls:** Interface between applications and the OS kernel (e.g., fork(), exec(), open())
   - **Scheduling Algorithms:** FCFS, Round Robin, SJF — decide which process gets CPU time

3. **Performance Metrics:**
   - Context switch overhead: microseconds
   - Memory access time: nanoseconds (RAM) vs milliseconds (disk)
   - Throughput: processes completed per unit time''';

    if (isNetwork) return '''## Key Technical Concepts

1. **Core Definition:**
   $topic deals with the principles and protocols enabling reliable, efficient communication between networked devices across local and global infrastructures.

2. **Structural Mechanics:**
   - **OSI Model (7 layers):** Physical → Data Link → Network → Transport → Session → Presentation → Application
   - **TCP vs UDP:** TCP guarantees delivery (3-way handshake); UDP prioritises speed (streaming, gaming)
   - **Routing:** Packets are forwarded hop-by-hop using routing tables and algorithms (Dijkstra, OSPF)

3. **Performance Metrics:**
   - Latency: time for a packet to travel source → destination
   - Bandwidth: maximum data transfer rate (Mbps / Gbps)
   - Packet loss: % of dropped packets under congestion''';

    if (isML) return '''## Key Technical Concepts

1. **Core Definition:**
   $topic is a branch of Artificial Intelligence that enables systems to learn from data and improve their performance without explicit programming.

2. **Structural Mechanics:**
   - **Training Phase:** Model learns by minimising a loss function over labelled data using gradient descent
   - **Inference Phase:** Trained model predicts outputs for new, unseen inputs
   - **Overfitting vs Underfitting:** Regularisation techniques (L1, L2, Dropout) prevent overfit

3. **Performance Metrics:**
   - Accuracy, Precision, Recall, F1-Score for classification
   - MSE, RMSE, MAE for regression
   - AUC-ROC for binary classification performance''';

    if (isAlgo) return '''## Key Technical Concepts

1. **Core Definition:**
   $topic is a step-by-step computational procedure that solves a specific problem class in a finite number of operations, with guaranteed correctness and measurable efficiency.

2. **Structural Mechanics:**
   - **Divide & Conquer:** Break problem into sub-problems, solve recursively, combine results
   - **Dynamic Programming:** Memoize overlapping sub-problems to avoid redundant computation
   - **Greedy Strategy:** Make locally optimal choices at each step, hoping for global optimum

3. **Complexity Analysis:**
   - Best case: O(1) or O(log n) for well-structured inputs
   - Average case: O(n log n) — typical for comparison-based algorithms
   - Worst case: O(n²) for degenerate or adversarial inputs''';

    if (isOOP) return '''## Key Technical Concepts

1. **Core Definition:**
   $topic is a software design paradigm that models real-world entities as objects, bundling data (attributes) and behaviour (methods) within well-defined class hierarchies.

2. **Four Pillars:**
   - **Encapsulation:** Hide internal state; expose only through controlled interfaces
   - **Inheritance:** Child classes reuse and extend parent class behaviour
   - **Polymorphism:** Same interface, different implementations (method overriding / overloading)
   - **Abstraction:** Expose only essential details; hide implementation complexity

3. **Design Principles (SOLID):**
   - S — Single Responsibility, O — Open/Closed, L — Liskov Substitution
   - I — Interface Segregation, D — Dependency Inversion''';

    if (isMath) return '''## Key Technical Concepts

1. **Core Definition:**
   $topic is a branch of mathematics providing the formal tools for modelling, analysis, and computation in engineering, physics, and computer science.

2. **Fundamental Principles:**
   - **Analytical Foundation:** Formal definitions, axioms, and theorems establish rigorous reasoning
   - **Computational Methods:** Numerical techniques approximate solutions where analytical forms are intractable
   - **Engineering Applications:** Used in signal processing, control systems, cryptography, and AI

3. **Key Formulae:**
   - Core identity relationships that define the domain
   - Complexity of numerical methods: O(n²) to O(n³) for matrix operations
   - Convergence criteria for iterative methods''';

    // Generic fallback for any other domain
    return '''## Key Technical Concepts

1. **Core Definition:**
   $topic is a structured concept in the engineering field that provides systematic solutions to a well-defined class of problems with measurable efficiency.

2. **Structural Mechanics:**
   - **Initialization:** System sets up state, validates inputs, allocates resources
   - **Core Processing:** Main logic executes — transforming, routing, or computing the result
   - **Termination:** Output is produced, resources released, state cleaned up

3. **Performance Metrics:**
   - Best Case: O(1) — direct access or immediate result
   - Average Case: O(log n) — typical balanced execution
   - Worst Case: O(n) or O(n²) — degenerate input or unoptimised path''';
  }

  String _domainCode(String topic, String lang, bool isDB, bool isOS,
      bool isML, bool isAlgo, bool isOOP) {
    if (isDB) return '''```sql
-- $topic: Example SQL Implementation

-- Create sample table
CREATE TABLE students (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  branch VARCHAR(50),
  semester INT,
  gpa DECIMAL(3,2)
);

-- Insert records
INSERT INTO students (name, branch, semester, gpa)
VALUES ('Alice', 'CS', 6, 9.2), ('Bob', 'IT', 4, 8.7);

-- Query with filter and sort (uses index on semester)
SELECT name, gpa
FROM students
WHERE semester = 6
ORDER BY gpa DESC;

-- Aggregate query
SELECT branch, AVG(gpa) AS avg_gpa
FROM students
GROUP BY branch
HAVING AVG(gpa) > 8.0;
```''';

    if (isOS) return '''```c
// $topic: Example C Implementation

#include <stdio.h>
#include <pthread.h>
#include <semaphore.h>

sem_t semaphore;

void* process(void* arg) {
    int id = *(int*)arg;
    sem_wait(&semaphore);      // Enter critical section
    printf("Process %d executing\\n", id);
    sem_post(&semaphore);      // Leave critical section
    return NULL;
}

int main() {
    pthread_t threads[3];
    int ids[] = {1, 2, 3};
    sem_init(&semaphore, 0, 1); // Binary semaphore

    for (int i = 0; i < 3; i++)
        pthread_create(&threads[i], NULL, process, &ids[i]);
    for (int i = 0; i < 3; i++)
        pthread_join(threads[i], NULL);

    sem_destroy(&semaphore);
    return 0;
}
```''';

    if (isML) return '''```python
# $topic: Example Python Implementation
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

# Generate sample dataset
np.random.seed(42)
X = np.random.randn(200, 3)  # 200 samples, 3 features
y = (X[:, 0] + X[:, 1] > 0).astype(int)  # Binary labels

# Split and scale
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
scaler = StandardScaler()
X_train = scaler.fit_transform(X_train)
X_test = scaler.transform(X_test)

# Simple gradient descent implementation
def sigmoid(z):
    return 1 / (1 + np.exp(-z))

def predict(X, weights):
    return sigmoid(X @ weights)

weights = np.zeros(X_train.shape[1])
lr = 0.01
for epoch in range(100):
    preds = predict(X_train, weights)
    grad = X_train.T @ (preds - y_train) / len(y_train)
    weights -= lr * grad

accuracy = np.mean(predict(X_test, weights).round() == y_test)
print(f"Accuracy: {accuracy:.2%}")
```''';

    if (isAlgo) return '''```dart
// $topic: Dart Implementation

// Merge Sort — O(n log n) divide and conquer
List<int> mergeSort(List<int> arr) {
  if (arr.length <= 1) return arr;

  final mid = arr.length ~/ 2;
  final left = mergeSort(arr.sublist(0, mid));
  final right = mergeSort(arr.sublist(mid));

  return _merge(left, right);
}

List<int> _merge(List<int> a, List<int> b) {
  final result = <int>[];
  int i = 0, j = 0;
  while (i < a.length && j < b.length) {
    if (a[i] <= b[j]) result.add(a[i++]);
    else result.add(j[j++]);
  }
  result.addAll(a.sublist(i));
  result.addAll(b.sublist(j));
  return result;
}

void main() {
  final data = [64, 34, 25, 12, 22, 11, 90];
  print('Unsorted: \$data');
  print('Sorted:   \${mergeSort(data)}');
  // Complexity: O(n log n) time, O(n) space
}
```''';

    if (isOOP) return '''```dart
// $topic: OOP Design in Dart

abstract class Shape {
  double area();           // Abstract method
  String describe() => 'Shape with area: \${area().toStringAsFixed(2)}';
}

class Circle extends Shape {
  final double radius;
  Circle(this.radius);

  @override
  double area() => 3.14159 * radius * radius;
}

class Rectangle extends Shape {
  final double width, height;
  Rectangle(this.width, this.height);

  @override
  double area() => width * height;
}

// Polymorphism in action
void printShapeInfo(Shape shape) {
  print(shape.describe());  // Works for any Shape subclass
}

void main() {
  final shapes = [Circle(5.0), Rectangle(4.0, 6.0)];
  for (final s in shapes) printShapeInfo(s);
}
```''';

    // Generic Dart code for any other topic
    final cls = topic.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return '''```dart
// $topic: Dart Implementation

class ${cls}System {
  final String id;
  final List<int> data;
  ${cls}System({required this.id, required this.data});

  // Core operation — O(n) linear pass
  Map<String, dynamic> analyse() {
    if (data.isEmpty) return {'error': 'No data provided'};
    final sum = data.reduce((a, b) => a + b);
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    return {
      'id': id,
      'count': data.length,
      'sum': sum,
      'min': min,
      'max': max,
      'average': sum / data.length,
    };
  }
}

void main() {
  final system = ${cls}System(
    id: 'demo-001',
    data: [15, 42, 8, 73, 31, 56],
  );
  final result = system.analyse();
  result.forEach((key, value) => print('\$key: \$value'));
}
```''';
  }

  String _domainQuestions(String topic, bool isDB, bool isOS, bool isNetwork,
      bool isML, bool isAlgo) {
    if (isDB) return '''1. **Explain the difference between DDL and DML commands in $topic with examples.**
   *Guidance:* DDL = CREATE, ALTER, DROP. DML = SELECT, INSERT, UPDATE, DELETE. Give one example each.
2. **What are ACID properties and why are they critical in $topic?**
   *Guidance:* Define each property and explain what fails if any one is violated.
3. **How does indexing improve query performance in $topic? What are its trade-offs?**
   *Guidance:* B-Tree indexing reduces O(n) scans to O(log n). Discuss write overhead and storage cost.''';

    if (isOS) return '''1. **Explain the difference between a process and a thread in the context of $topic.**
   *Guidance:* Processes are isolated; threads share memory within a process. Compare creation cost.
2. **What is deadlock? State the four necessary conditions and how $topic prevents it.**
   *Guidance:* Mutual exclusion, Hold & Wait, No preemption, Circular wait. Prevention vs Avoidance.
3. **Compare FCFS, SJF, and Round Robin scheduling in terms of $topic.**
   *Guidance:* Discuss turnaround time, waiting time, starvation, and real-time suitability.''';

    if (isNetwork) return '''1. **Explain the role of each layer of the OSI model in $topic.**
   *Guidance:* Map each layer to a real protocol (e.g., HTTP=Application, TCP=Transport, IP=Network).
2. **Compare TCP and UDP. When would you choose each in $topic?**
   *Guidance:* TCP = reliable, ordered, slower. UDP = fast, unreliable. Use UDP for live streaming.
3. **How does Dijkstra's algorithm find the shortest path in a network related to $topic?**
   *Guidance:* Greedy BFS with priority queue. O((V+E) log V) complexity.''';

    if (isML) return '''1. **Explain the bias-variance tradeoff in $topic and how regularisation helps.**
   *Guidance:* High bias = underfitting; high variance = overfitting. L1/L2 penalise large weights.
2. **Compare supervised, unsupervised, and reinforcement learning with examples from $topic.**
   *Guidance:* Supervised = labelled data (SVM); Unsupervised = clustering (K-Means); RL = reward signal.
3. **How does gradient descent minimise the loss function in $topic?**
   *Guidance:* Iteratively update weights opposite to gradient direction. Discuss learning rate choice.''';

    if (isAlgo) return '''1. **Prove the time complexity of $topic using a recurrence relation and Master Theorem.**
   *Guidance:* Set up T(n) = aT(n/b) + f(n). Apply Master Theorem cases to derive O notation.
2. **When would you choose dynamic programming over greedy for $topic?**
   *Guidance:* DP = overlapping sub-problems + optimal substructure. Greedy = locally optimal choices.
3. **Trace through $topic step-by-step for the input [5, 3, 8, 1, 9, 2].**
   *Guidance:* Show each comparison, swap, and state — draw the execution table for full marks.''';

    // Generic questions for any domain
    return '''1. **Define $topic and explain its significance in $topic's domain with real-world examples.**
   *Guidance:* Use the Define → Explain → Apply → Analyse formula for a complete answer.
2. **What are the time and space complexity trade-offs of $topic? How can they be optimised?**
   *Guidance:* State best/average/worst case. Mention specific optimisation techniques.
3. **Compare $topic with an alternative approach. When would you prefer each?**
   *Guidance:* Build a comparison table with at least 4 criteria. Justify with examples.''';
  }

  // ── DocuChat Study Buddy ───────────────────────────────────────────────────
  Future<String> askStudyBuddy({
    required String materialTitle,
    required String materialDescription,
    required String userQuestion,
    required List<Map<String, String>> chatHistory,
  }) async {
    final historyStr = chatHistory.map((m) => '${m['sender']}: ${m['text']}').join('\n');
    final prompt = '''You are "DocuChat", a friendly AI Study Buddy.
Document: "$materialTitle" — $materialDescription
Chat history:
$historyStr
Student asks: "$userQuestion"
Give a helpful, precise answer in clean markdown. Max 3 paragraphs.''';

    final aiResponse = await _callGroq(prompt);
    if (aiResponse != null && aiResponse.isNotEmpty) return aiResponse;

    return _smartFallback(userQuestion, materialTitle);
  }

  // ── Universal Smart Fallback ───────────────────────────────────────────────
  String _smartFallback(String question, String docTitle) {
    final q = question.toLowerCase().trim();

    // Extract the actual topic the student is asking about
    final topic = _extractTopic(q, docTitle);

    // Route by question type
    if (_matches(q, ['summarize', 'summary', 'overview', 'brief'])) {
      return _summary(topic, docTitle);
    } else if (_matches(q, ['quiz', 'test me', 'mcq', 'practice question', 'question me'])) {
      return _quiz(topic);
    } else if (_matches(q, ['application', 'use case', 'real world', 'real-world', 'used in', 'where is', 'example of'])) {
      return _applications(topic);
    } else if (_matches(q, ['what is', 'define', 'definition', 'meaning', 'what do you mean', 'what are'])) {
      return _definition(topic);
    } else if (_matches(q, ['how does', 'how do', 'explain', 'describe', 'working', 'mechanism', 'how it works'])) {
      return _explanation(topic);
    } else if (_matches(q, ['types', 'type of', 'kinds', 'classify', 'categories', 'classification'])) {
      return _types(topic);
    } else if (_matches(q, ['advantage', 'benefit', 'pros', 'disadvantage', 'cons', 'limitation', 'drawback'])) {
      return _proscons(topic);
    } else if (_matches(q, ['difference', 'compare', ' vs ', 'versus', 'distinguish', 'contrast'])) {
      return _comparison(topic, q);
    } else if (_matches(q, ['complexity', 'time complexity', 'space complexity', 'big o', 'big-o'])) {
      return _complexity(topic);
    } else if (_matches(q, ['algorithm', 'steps', 'procedure', 'process', 'flow'])) {
      return _algorithm(topic);
    } else if (_matches(q, ['formula', 'equation', 'calculate', 'derive', 'proof'])) {
      return _formula(topic);
    } else if (_matches(q, ['diagram', 'draw', 'structure', 'architecture', 'design'])) {
      return _diagram(topic);
    } else if (_matches(q, ['history', 'origin', 'invented', 'discovered', 'when was'])) {
      return _history(topic);
    } else if (_matches(q, ['code', 'program', 'implement', 'write', 'snippet'])) {
      return _codeExample(topic);
    } else {
      return _generalAnswer(topic, question);
    }
  }

  // ── Topic Extractor ────────────────────────────────────────────────────────
  String _extractTopic(String q, String docTitle) {
    final removals = [
      'what is', 'what are', 'what do you mean by', 'define', 'definition of',
      'explain', 'describe', 'how does', 'how do', 'how is', 'how are',
      'applications of', 'application of', 'uses of', 'use of', 'use cases of',
      'types of', 'type of', 'kinds of', 'categories of', 'classification of',
      'advantages of', 'disadvantages of', 'benefits of', 'limitations of',
      'difference between', 'compare', 'complexity of', 'algorithm for',
      'history of', 'give me', 'tell me about', 'explain about',
      'can you explain', 'i want to know about', 'summarize', 'quiz me on',
      'the', 'a ', 'an ', '?', 'please', 'in', 'about',
    ];

    String topic = q;
    for (final r in removals) {
      topic = topic.replaceAll(r, ' ');
    }
    topic = topic.trim().replaceAll(RegExp(r'\s+'), ' ');

    // If extraction left nothing meaningful, fall back to document title
    if (topic.isEmpty || topic.length < 3) return docTitle;

    // Title-case the extracted topic
    return topic.split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ')
        .trim();
  }

  bool _matches(String q, List<String> keywords) =>
      keywords.any((k) => q.contains(k));

  // ── Answer Templates (all universal — use extracted topic) ─────────────────

  String _summary(String topic, String docTitle) =>
      '### Summary: $topic\n\n'
      '* **What it is:** $topic is a fundamental concept widely studied in engineering and computer science curricula.\n'
      '* **Core Purpose:** It provides a systematic, efficient approach to solving a well-defined class of problems.\n'
      '* **Key Takeaway:** Mastery of $topic requires understanding its definition, working mechanism, types, and real-world applications.\n\n'
      '*Want a quiz, deeper explanation, or list of applications? Just ask!*';

  String _quiz(String topic) =>
      '### Quick Quiz: $topic\n\n'
      '**Q:** Which statement best describes $topic?\n\n'
      '1. It is only used in theoretical computer science with no practical value\n'
      '2. It provides an efficient, structured solution to a well-defined class of problems\n'
      '3. It always requires O(n²) time and cannot be optimised\n'
      '4. It completely replaces all other related concepts\n\n'
      '*Reply 1, 2, 3, or 4 — I will reveal the answer with a full explanation!*';

  String _applications(String topic) =>
      '### Real-World Applications of $topic\n\n'
      '**In Software & Systems:**\n'
      '* Used in core system design, scalable algorithms, and production-level infrastructure\n'
      '* Applied by companies like Google, Amazon, and Microsoft in search engines, cloud platforms, and databases\n\n'
      '**In Operating Systems:**\n'
      '* Supports process scheduling, memory management, and file I/O subsystems\n\n'
      '**In Databases & Networking:**\n'
      '* Enables efficient query optimisation, indexing, routing protocols, and packet management\n\n'
      '**In Embedded & Real-Time Systems:**\n'
      '* Deployed in microcontrollers, IoT sensors, automotive ECUs, and medical devices\n\n'
      '**In Academia & Research:**\n'
      '* Foundational to algorithm design, complexity theory, and software engineering coursework\n\n'
      '*Exam tip: Always name at least one real product or company (e.g., "Google uses X for Y") — it earns extra marks!*';

  String _definition(String topic) =>
      '### Definition: $topic\n\n'
      '**$topic** is formally defined as:\n\n'
      '> *A structured concept or system designed to solve a specific class of problems in an efficient, repeatable, and scalable manner.*\n\n'
      '**Key characteristics:**\n'
      '* Operates on a defined set of inputs and produces predictable outputs\n'
      '* Measured by time complexity (speed) and space complexity (memory usage)\n'
      '* Applied across software engineering, systems design, databases, and networking\n\n'
      '**In exams, a complete definition includes:**\n'
      '1. **What it IS** — the concept itself\n'
      '2. **What it DOES** — its function or purpose\n'
      '3. **Where it is USED** — real-world domain or context\n\n'
      '*Want me to explain how $topic works step-by-step?*';

  String _explanation(String topic) =>
      '### How $topic Works\n\n'
      '$topic operates through a structured sequence of well-defined steps:\n\n'
      '**Step 1 — Initialization**\n'
      '   The system sets up its starting state, defines input parameters, and checks boundary conditions.\n\n'
      '**Step 2 — Core Processing**\n'
      '   The main logic executes — iterating, comparing, transforming, or routing data according to its rules.\n\n'
      '**Step 3 — State Management**\n'
      '   At each stage, state transitions occur based on conditions. Edge cases (null, overflow, empty input) are handled here.\n\n'
      '**Step 4 — Output / Result**\n'
      '   The final computed result is returned, stored, or transmitted to the next system.\n\n'
      '**Step 5 — Cleanup**\n'
      '   Resources (memory, file handles, connections) are released and the process terminates cleanly.\n\n'
      '*Exam tip: Always draw a flowchart — visual answers consistently score higher marks!*';

  String _types(String topic) =>
      '### Types of $topic\n\n'
      '1. **Basic / Primitive Type**\n'
      '   The foundational form. Directly implements the core concept with minimal overhead. Used in introductory scenarios.\n\n'
      '2. **Enhanced / Optimised Type**\n'
      '   Builds on the basic type with additional features — faster traversal, error recovery, or memory efficiency.\n\n'
      '3. **Distributed / Parallel Type**\n'
      '   Designed to operate across multiple nodes, processors, or machines. Enables scalability and fault tolerance.\n\n'
      '4. **Real-Time / Embedded Type**\n'
      '   Operates under strict time constraints. Used in mission-critical systems like medical devices and aircraft.\n\n'
      '5. **Hybrid / Specialised Type**\n'
      '   Combines principles from multiple paradigms for specific use cases in AI, databases, or cloud infrastructure.\n\n'
      '*Tip: Draw a classification tree in exams — it earns extra presentation marks!*';

  String _proscons(String topic) =>
      '### Advantages & Disadvantages of $topic\n\n'
      '**Advantages:**\n'
      '* Provides a structured, predictable, and repeatable solution\n'
      '* Reduces development time by leveraging proven patterns\n'
      '* Scales effectively across small and enterprise-level systems\n'
      '* Well-documented with extensive academic and industry support\n'
      '* Reduces complexity and improves code maintainability\n\n'
      '**Disadvantages:**\n'
      '* May introduce overhead in trivial or very small-scale scenarios\n'
      '* Requires solid foundational knowledge before effective application\n'
      '* Edge cases (boundary values, null inputs) demand careful handling\n'
      '* Implementation complexity increases in distributed or parallel environments\n\n'
      '*Exam tip: List at least 3 advantages AND 2 disadvantages with brief justifications for full marks!*';

  String _comparison(String topic, String q) {
    // Try to extract both sides of the comparison
    final vs = q.contains(' vs ') ? q.split(' vs ') :
               q.contains('versus') ? q.split('versus') :
               q.contains('difference between') ? q.replaceAll('difference between', '').split(' and ') :
               [topic, 'Alternative Approach'];
    final a = vs[0].trim();
    final b = vs.length > 1 ? vs[1].trim() : 'Alternative Approach';
    final aTitle = a[0].toUpperCase() + a.substring(1);
    final bTitle = b[0].toUpperCase() + b.substring(1);
    return '### Comparison: $aTitle vs $bTitle\n\n'
        '| Aspect | $aTitle | $bTitle |\n'
        '|---|---|---|\n'
        '| **Definition** | Foundational approach for its problem class | Alternative paradigm with different trade-offs |\n'
        '| **Time Complexity** | O(log n) or better in optimal cases | Varies — O(n) to O(n²) in general |\n'
        '| **Space Complexity** | Usually O(1) to O(n) | Depends on implementation strategy |\n'
        '| **Best For** | Structured, predictable inputs | Dynamic or irregular data patterns |\n'
        '| **Limitation** | Less flexible with irregular constraints | Higher constant factors or memory use |\n'
        '| **Real-World Use** | Databases, compilers, OS kernels | Networking, AI models, distributed systems |\n\n'
        '*Key rule for exams: Always justify comparisons with Big-O notation AND a real-world example. That combination earns full marks!*';
  }

  String _complexity(String topic) =>
      '### Time & Space Complexity of $topic\n\n'
      '| Case | Time Complexity | Explanation |\n'
      '|---|---|---|\n'
      '| **Best Case** | O(1) | Direct access or immediate match |\n'
      '| **Average Case** | O(log n) | Typical execution with balanced input |\n'
      '| **Worst Case** | O(n) or O(n²) | Degenerate input or no optimisation |\n\n'
      '**Space Complexity:** O(n) for storing input; O(1) auxiliary if in-place\n\n'
      '**How to improve complexity:**\n'
      '* Use hash-based structures to reduce O(n) lookups to O(1)\n'
      '* Apply divide-and-conquer to reduce O(n²) to O(n log n)\n'
      '* Use memoisation/dynamic programming to eliminate redundant computation\n\n'
      '*In technical interviews: always state best, average, AND worst case — incomplete answers lose marks!*';

  String _algorithm(String topic) =>
      '### Algorithm / Procedure for $topic\n\n'
      '```\nALGORITHM $topic\nINPUT:  A set of elements or problem parameters\nOUTPUT: The desired result or transformed data\n\n'
      'BEGIN\n'
      '  Step 1: Validate input — check for null, empty, or out-of-range values\n'
      '  Step 2: Initialise required variables, pointers, and auxiliary structures\n'
      '  Step 3: Apply the core operation iteratively or recursively:\n'
      '           - Compare / transform / route elements based on conditions\n'
      '           - Update state at each iteration\n'
      '  Step 4: Handle edge cases — overflow, underflow, cycle detection\n'
      '  Step 5: Return or store the final computed result\n'
      '  Step 6: Release allocated resources\n'
      'END\n```\n\n'
      '*Tip: Write pseudocode exactly like this in exams — it is cleaner than raw code and earns structure marks!*';

  String _formula(String topic) =>
      '### Key Formulas & Equations: $topic\n\n'
      '**Core Relationship:**\n'
      '> Output = f(Input, Parameters, Constraints)\n\n'
      '**Complexity Formula:**\n'
      '* T(n) = Time taken for input of size n\n'
      '* Best case: T(n) = O(1)\n'
      '* Average case: T(n) = O(log n)\n'
      '* Worst case: T(n) = O(n)\n\n'
      '**Recurrence Relation (if divide-and-conquer):**\n'
      '> T(n) = 2·T(n/2) + O(n)  →  Solves to O(n log n) by Master Theorem\n\n'
      '**Master Theorem (for T(n) = aT(n/b) + f(n)):**\n'
      '* If f(n) = O(n^c) where c < log_b(a) → T(n) = O(n^log_b(a))\n'
      '* If f(n) = O(n^log_b(a)) → T(n) = O(n^log_b(a) · log n)\n'
      '* If f(n) = Ω(n^c) where c > log_b(a) → T(n) = O(f(n))\n\n'
      '*Always derive the formula step-by-step in exams — the working earns as many marks as the final answer!*';

  String _diagram(String topic) =>
      '### Structure / Architecture of $topic\n\n'
      '```\n'
      '┌─────────────────────────────────────┐\n'
      '│           $topic System              │\n'
      '├─────────────┬───────────────────────┤\n'
      '│   INPUT     │  ┌─────────────────┐  │\n'
      '│  (Raw Data) │  │  Core Processor │  │\n'
      '│             │→ │  - Validate     │  │\n'
      '│             │  │  - Transform    │  │\n'
      '│             │  │  - Route        │  │\n'
      '│             │  └────────┬────────┘  │\n'
      '│             │           ↓           │\n'
      '│             │  ┌────────────────┐   │\n'
      '│             │  │ State Manager  │   │\n'
      '│             │  │ - Track state  │   │\n'
      '│             │  │ - Handle edges │   │\n'
      '│             │  └────────┬───────┘   │\n'
      '│             │           ↓           │\n'
      '│   OUTPUT    │  ┌────────────────┐   │\n'
      '│  (Result)   │← │  Result Store  │   │\n'
      '└─────────────┴──└────────────────┘───┘\n'
      '```\n\n'
      '*Always label your diagrams clearly in exams. A well-drawn diagram alone can earn 4-5 marks!*';

  String _history(String topic) =>
      '### History & Origin of $topic\n\n'
      '**Origins:**\n'
      '$topic emerged from foundational work in computer science and mathematics during the mid-to-late 20th century, '
      'as researchers sought systematic solutions to recurring computational problems.\n\n'
      '**Key Milestones:**\n'
      '* **1950s–60s:** Theoretical foundations established in academic literature\n'
      '* **1970s–80s:** Formal algorithms published and standardised; adopted in early systems programming\n'
      '* **1990s–2000s:** Widespread adoption in commercial software, databases, and operating systems\n'
      '* **2010s–present:** Optimised variants developed for distributed systems, cloud infrastructure, and AI/ML pipelines\n\n'
      '**Impact:**\n'
      '$topic is now a cornerstone of modern CS education and is directly applied in industry-grade systems worldwide.\n\n'
      '*Exam tip: Even if you do not know the exact year, describe the evolution in phases — it shows analytical thinking!*';

  String _codeExample(String topic) {
    final cls = topic.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return '### Code Implementation: $topic\n\n'
        '```dart\n'
        '// $topic — Dart Implementation\n'
        'class ${cls}Solver {\n'
        '  final List<int> data;\n'
        '  ${cls}Solver(this.data);\n\n'
        '  // Core operation\n'
        '  int execute() {\n'
        '    if (data.isEmpty) throw Exception("Input cannot be empty");\n'
        '    int result = data[0];\n'
        '    for (int i = 1; i < data.length; i++) {\n'
        '      // Apply $topic logic here\n'
        '      result = _process(result, data[i]);\n'
        '    }\n'
        '    return result;\n'
        '  }\n\n'
        '  int _process(int current, int next) {\n'
        '    // Replace with actual $topic operation\n'
        '    return current + next;\n'
        '  }\n'
        '}\n\n'
        'void main() {\n'
        '  final solver = ${cls}Solver([10, 20, 30, 40]);\n'
        '  print("Result: \${solver.execute()}");\n'
        '}\n'
        '```\n\n'
        '**Time Complexity:** O(n) — single pass through input\n'
        '**Space Complexity:** O(1) — no auxiliary structure needed\n\n'
        '*In exams: always add comments explaining each section and state the complexity below the code block!*';
  }

  String _generalAnswer(String topic, String originalQuestion) =>
      '### Answer: $topic\n\n'
      'Great question! Here is a structured academic response about **$topic**:\n\n'
      '**Core Concept:**\n'
      '$topic is a key subject in engineering and computer science. '
      'It provides a rigorous framework for solving a well-defined class of problems efficiently and reliably.\n\n'
      '**Why It Matters:**\n'
      '* Forms the theoretical basis for real-world systems in OS, databases, networks, and AI\n'
      '* Understanding $topic deeply is essential for technical interviews at top tech companies\n'
      '* Frequently tested in university exams through application, analysis, and design questions\n\n'
      '**How to Answer in Exams:**\n'
      '1. **Define** — state what $topic is in 1-2 sentences\n'
      '2. **Explain** — describe how it works step-by-step\n'
      '3. **Apply** — give a concrete real-world example\n'
      '4. **Analyse** — mention time/space complexity or trade-offs\n\n'
      '*Try asking: "explain $topic", "applications of $topic", "types of $topic", or "quiz me on $topic" for a more focused answer!*';

  // ── Group Chat Summarizer ──────────────────────────────────────────────────
  Future<String> generateGroupChatSummary(List<Map<String, dynamic>> messages) async {
    final messagesStr = messages.map((m) =>
        '${m['senderName'] ?? 'Unknown'}: ${m['message'] ?? ''}').join('\n');

    final prompt = '''You are "StudyCoPilot", an advanced academic AI.
Analyse this group chat and generate a structured Markdown summary with:
### Discussion Highlights
### Shared Resources & Links
### Action Plan & Reminders

Chat transcript:
$messagesStr''';

    final aiResponse = await _callGroq(prompt);
    if (aiResponse != null && aiResponse.isNotEmpty) return aiResponse;

    await Future.delayed(const Duration(milliseconds: 500));
    if (messages.isEmpty) {
      return '### Discussion Highlights\n* No active discussions yet. Start chatting for an instant AI recap!\n\n'
          '### Shared Resources & Links\n* None shared yet.\n\n'
          '### Action Plan & Reminders\n* No sessions scheduled. Start a conversation!';
    }

    final senders = messages.map((m) => m['senderName'] ?? 'Classmate').toSet().take(3).join(', ');
    final last = messages.last['message'] ?? 'study materials';

    return '### Discussion Highlights\n'
        '* **Active participants:** $senders\n'
        '* **Latest focus:** *"$last"*\n'
        '* Group is actively exchanging academic insights and resolving course queries.\n\n'
        '### Shared Resources & Links\n'
        '* Check the Materials tab in the dashboard for latest uploaded PDFs and lecture notes.\n\n'
        '### Action Plan & Reminders\n'
        '* Continue sharing practice questions and study notes before the next lecture.\n'
        '* Coordinate group study sessions via this channel!';
  }

  // ── Groq REST API Call ────────────────────────────────────────────────────
  Future<String?> _callGroq(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': _groqModel,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 2048,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String?;
        print('Groq API success!');
        return content;
      } else {
        print('Groq API error: ${response.statusCode} — ${response.body}');
        return null;
      }
    } catch (e) {
      print('Groq call exception: $e');
      return null;
    }
  }
}
