const test = require('node:test');
const assert = require('node:assert');
const { searchFilter, relevance, queryWords } = require('../src/utils/courseSearch');

test('partial words in any order match', () => {
  assert.ok(relevance('bio', 'Biology S3') > 0);
  assert.ok(relevance('s3 bio', 'Biology S3') > 0);
  assert.strictEqual(relevance('bio s4', 'Biology S3'), 0);
});

test('titles starting with the query rank first', () => {
  assert.ok(relevance('bio', 'Biology S3') > relevance('bio', 'Introduction to Biology'));
  assert.ok(relevance('bio', 'Introduction to Biology') > relevance('bio', 'Chemistry', 'a biology topic'));
});

test('special characters are searched literally', () => {
  const f = searchFilter('c++ (intro)');
  const re = f.$and[0].$or[0].title;
  assert.ok(re instanceof RegExp);
  assert.ok(re.test('C++ for beginners'));
  assert.ok(!re.test('C for beginners'));
});

test('empty and very long queries are safe', () => {
  assert.strictEqual(searchFilter('   '), null);
  assert.ok(queryWords('a b c d e f g h i').length <= 6);
  assert.ok(queryWords('x'.repeat(500))[0].length <= 40);
});
