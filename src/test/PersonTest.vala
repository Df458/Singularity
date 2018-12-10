/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2016  Hugues Ross <hugues.ross@gmail.com>

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

namespace Singularity.Tests {
    public class PersonTest : UnitTest {
        public string name { get { return "Person"; } }
        public TestCase[] test_cases;
        public void add_tests(string path) {
            add_cases(path, {
                TestCase("name", testPersonName),
                TestCase("url", testPersonURL),
                TestCase("email", testPersonEmail),
                TestCase("is_valid_name", testPersonIsValidName),
                TestCase("is_valid_email", testPersonIsValidEmail),
                TestCase("is_invalid_url", testPersonIsInvalidURL),
                TestCase("is_invalid_empty_name", testPersonIsInvalidEmptyName),
                TestCase("is_invalid_empty_email", testPersonIsInvalidEmptyEmail),
                TestCase("is_invalid_null", testPersonIsInvalidNull),
            });
        }

        private static void testPersonName() {
            Person person = new Person("Alice");
            assert ("Alice" == person.name);
        }
        private static void testPersonURL() {
            Person person = new Person("Bob", "http://example.com");
            assert ("http://example.com" == person.url);
        }
        private static void testPersonEmail() {
            Person person = new Person("Chris", "http://example.com", "chris@example.com");
            assert ("chris@example.com" == person.email);
        }
        private static void testPersonIsValidName() {
            Person person = new Person("Alice");
            assert (person.is_valid);
        }
        private static void testPersonIsValidEmail() {
            Person person = new Person(null, null, "bob@example.com");
            assert (person.is_valid);
        }
        private static void testPersonIsInvalidURL() {
            Person person = new Person(null, "http://example.com", null);
            assert (!person.is_valid);
        }
        private static void testPersonIsInvalidEmptyName() {
            Person person = new Person("");
            assert (!person.is_valid);
        }
        private static void testPersonIsInvalidEmptyEmail() {
            Person person = new Person(null, null, "");
            assert (!person.is_valid);
        }
        private static void testPersonIsInvalidNull() {
            Person person = new Person(null);
            assert (!person.is_valid);
        }
    }
}
