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
using Valadate;

namespace Singularity.Tests
{
    [Test (name="Person TestCases")]
    public class PersonTest : Framework.TestCase
    {
        [Test (name="person_name")]
        public void testPersonName()
        {
            Person person = Person("Alice");
            Assert.equals("Alice", person.name, "wrong name");
        }
        [Test (name="person_url")]
        public void testPersonURL()
        {
            Person person = Person("Bob", "http://example.com");
            Assert.equals("http://example.com", person.url, "wrong url");
        }
        [Test (name="person_email")]
        public void testPersonEmail()
        {
            Person person = Person("Chris", "http://example.com", "chris@example.com");
            Assert.equals("chris@example.com", person.email, "wrong email");
        }
        [Test (name="person_is_valid_name")]
        public void testPersonIsValidName()
        {
            Person person = Person("Alice");
            Assert.is_true(person.is_valid, "person with name is invalid");
        }
        [Test (name="person_is_valid_email")]
        public void testPersonIsValidEmail()
        {
            Person person = Person(null, null, "bob@example.com");
            Assert.is_true(person.is_valid, "person with an email is invalid");
        }
        [Test (name="person_is_invalid_url")]
        public void testPersonIsInvalidURL()
        {
            Person person = Person(null, "http://example.com", null);
            Assert.is_false(person.is_valid, "person with a url is valid");
        }
        [Test (name="person_is_invalid_empty_name")]
        public void testPersonIsInvalidEmptyName()
        {
            Person person = Person("");
            Assert.is_false(person.is_valid, "person with an empty name is valid");
        }
        [Test (name="person_is_invalid_empty_email")]
        public void testPersonIsInvalidEmptyEmail()
        {
            Person person = Person(null, null, "");
            Assert.is_false(person.is_valid, "person with an empty email is valid");
        }
        [Test (name="person_is_invalid_null")]
        public void testPersonIsInvalidNull()
        {
            Person person = Person(null);
            Assert.is_false(person.is_valid, "person with all null fields is valid");
        }
    }
}
